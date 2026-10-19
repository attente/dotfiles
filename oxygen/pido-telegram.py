#!/usr/bin/env python3
"""Telegram front-end for pido.

Send a text message to run pido with that message as the prompt. The bot
forwards -p and, unless the conversation was reset with /new, -c. The pido
output is sent back to the same chat. /stop cancels the active run and clears
queued messages.
"""

from __future__ import annotations

import asyncio
import logging
import os
import signal
from dataclasses import dataclass
from typing import NoReturn

from telegram import Message, Update
from telegram.constants import ChatAction
from telegram.ext import (
    Application,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "").strip()
ALLOWED_USER_ID = os.environ.get("TELEGRAM_ALLOWED_USER_ID", "").strip()
PIDO_PATH = os.environ.get("PIDO_PATH", "/home/william/.william/etc/bin/pido")
PIDO_TIMEOUT_SECONDS = int(os.environ.get("PIDO_TIMEOUT_SECONDS", "3600"))
REPLY_CHUNK_LIMIT = 4000

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
logger = logging.getLogger("pido-telegram")


@dataclass(slots=True)
class QueueItem:
    """A queued message or /new marker."""

    update_id: int
    chat_id: int
    message: Message
    prompt: str | None


prompt_queue: asyncio.Queue[QueueItem] = asyncio.Queue()
worker_task: asyncio.Task[None] | None = None
stop_update_id = 0
skip_continue: set[int] = set()


class PidoTimeout(Exception):
    """Raised when pido does not finish before the timeout."""


def is_allowed(update: Update) -> bool:
    """Return True only for the configured user in a private chat."""
    user = update.effective_user
    chat = update.effective_chat
    if user is None or chat is None:
        return False
    if chat.type != "private":
        logger.warning("ignoring update from non-private chat %s", chat.id)
        return False

    allowed = str(user.id) == ALLOWED_USER_ID
    if not allowed:
        logger.warning("ignoring update from unauthorized user id %s", user.id)
    return allowed


def split_message(text: str, limit: int = REPLY_CHUNK_LIMIT) -> list[str]:
    """Split text into chunks that fit within Telegram's message limit."""
    chunks: list[str] = []
    remaining = text

    while remaining:
        if len(remaining) <= limit:
            chunks.append(remaining)
            break

        split_at = remaining.rfind("\n", 0, limit)
        if split_at < limit // 2:
            split_at = remaining.rfind(" ", 0, limit)
        if split_at < limit // 2:
            split_at = limit

        chunks.append(remaining[:split_at].rstrip())
        remaining = remaining[split_at:].lstrip("\n")

    return [chunk for chunk in chunks if chunk]


def format_result(returncode: int, stdout: str, stderr: str) -> str:
    """Build the text sent back to Telegram after a pido run."""
    output = stdout.strip()
    errors = stderr.strip()

    if returncode == 0:
        return output or errors or "pido produced no output."

    parts = [f"pido exited with status {returncode}."]
    if output:
        parts.append(output)
    if errors:
        parts.append(errors)
    return "\n\n".join(parts)


async def terminate_process(process: asyncio.subprocess.Process) -> None:
    """Terminate pido's process group, escalating to SIGKILL if needed."""
    if process.returncode is not None:
        return

    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass

    try:
        await asyncio.wait_for(process.wait(), timeout=10)
        return
    except asyncio.TimeoutError:
        pass

    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    await process.wait()


async def run_pido(prompt: str, continue_session: bool) -> tuple[int, str, str]:
    """Run pido with the given prompt and return its exit status and output."""
    args = [PIDO_PATH, "-p"]
    if continue_session:
        args.append("-c")
    args.extend(["--", prompt])

    child_env = os.environ.copy()
    child_env.pop("TELEGRAM_BOT_TOKEN", None)

    process = await asyncio.create_subprocess_exec(
        *args,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        env=child_env,
        start_new_session=True,
    )

    try:
        stdout, stderr = await asyncio.wait_for(
            process.communicate(), timeout=PIDO_TIMEOUT_SECONDS
        )
    except asyncio.TimeoutError:
        await terminate_process(process)
        raise PidoTimeout from None
    except asyncio.CancelledError:
        await terminate_process(process)
        raise

    return (
        process.returncode or 0,
        stdout.decode("utf-8", errors="replace"),
        stderr.decode("utf-8", errors="replace"),
    )


async def keep_typing(chat: object) -> None:
    """Show a typing indicator while pido is running."""
    try:
        while True:
            await chat.send_action(ChatAction.TYPING)  # type: ignore[attr-defined]
            await asyncio.sleep(4)
    except asyncio.CancelledError:
        pass
    except Exception:
        logger.debug("typing indicator failed", exc_info=True)


async def reply_with_result(message: object, text: str) -> None:
    """Send a result, splitting it if Telegram's limit requires it."""
    chunks = split_message(text)
    for index, chunk in enumerate(chunks):
        if index == 0:
            await message.reply_text(chunk)  # type: ignore[attr-defined]
        else:
            await message.chat.send_message(chunk)  # type: ignore[attr-defined]
            await asyncio.sleep(0.5)


def clear_prompt_queue() -> int:
    """Discard queued messages and return how many items were removed."""
    cleared = 0
    while True:
        try:
            prompt_queue.get_nowait()
        except asyncio.QueueEmpty:
            return cleared
        prompt_queue.task_done()
        cleared += 1


def ensure_worker() -> None:
    """Start the queue worker unless it is already running."""
    global worker_task
    if worker_task is not None and not worker_task.done():
        return
    worker_task = asyncio.create_task(worker_loop(), name="pido-worker")


async def execute_prompt(item: QueueItem, continue_session: bool) -> str:
    """Run pido for a queued item and return the response text."""
    typing_task = asyncio.create_task(keep_typing(item.message.chat))
    try:
        returncode, stdout, stderr = await run_pido(
            item.prompt or "", continue_session
        )
        return format_result(returncode, stdout, stderr)
    except PidoTimeout:
        return f"pido timed out after {PIDO_TIMEOUT_SECONDS} seconds."
    except FileNotFoundError:
        return f"pido was not found at {PIDO_PATH}."
    except asyncio.CancelledError:
        raise
    except Exception:
        logger.exception("pido failed")
        return "pido failed to start."
    finally:
        typing_task.cancel()
        await asyncio.gather(typing_task, return_exceptions=True)


async def process_queue_item(item: QueueItem) -> None:
    """Process one queued message or /new marker."""
    if item.update_id < stop_update_id:
        return

    if item.prompt is None:
        skip_continue.add(item.chat_id)
        await item.message.reply_text(
            "The next pido call will start a new session."
        )
        return

    continue_session = item.chat_id not in skip_continue
    skip_continue.discard(item.chat_id)
    response = await execute_prompt(item, continue_session)

    if item.update_id < stop_update_id:
        return
    await reply_with_result(item.message, response)


async def worker_loop() -> None:
    """Process queued items sequentially and cancel cleanly when asked."""
    while True:
        item = await prompt_queue.get()
        try:
            await process_queue_item(item)
        except asyncio.CancelledError:
            raise
        except Exception:
            logger.exception("failed to process queued message")
        finally:
            prompt_queue.task_done()


async def handle_message(
    update: Update, _context: ContextTypes.DEFAULT_TYPE
) -> None:
    """Queue an authorized user's text message for pido."""
    if not is_allowed(update):
        return

    message = update.effective_message
    chat = update.effective_chat
    if message is None or chat is None or message.text is None:
        return

    await prompt_queue.put(
        QueueItem(update.update_id, chat.id, message, message.text)
    )
    ensure_worker()


async def new_command(
    update: Update, _context: ContextTypes.DEFAULT_TYPE
) -> None:
    """Start a fresh pido session on the next message."""
    if not is_allowed(update):
        return

    chat = update.effective_chat
    message = update.effective_message
    if chat is None or message is None:
        return

    await prompt_queue.put(QueueItem(update.update_id, chat.id, message, None))
    ensure_worker()


async def stop_command(
    update: Update, _context: ContextTypes.DEFAULT_TYPE
) -> None:
    """Cancel the active pido run and discard queued messages."""
    if not is_allowed(update):
        return

    message = update.effective_message
    if message is None:
        return

    global stop_update_id, worker_task
    stop_update_id = max(stop_update_id, update.update_id)

    old_worker = worker_task
    worker_task = None
    if old_worker is not None:
        old_worker.cancel()
        await asyncio.gather(old_worker, return_exceptions=True)

    cleared = clear_prompt_queue()
    ensure_worker()

    if cleared:
        detail = f"Cleared {cleared} queued item{'s' if cleared != 1 else ''}."
    else:
        detail = "The message queue was already empty."
    await message.reply_text(f"Stopped pido. {detail}")


async def start_command(
    update: Update, _context: ContextTypes.DEFAULT_TYPE
) -> None:
    """Explain how to use the bot to an authorized user."""
    if not is_allowed(update):
        return

    message = update.effective_message
    if message is None:
        return

    await message.reply_text(
        "Send a text message to run pido. Use /new before a message to start "
        "a new session instead of continuing the previous one. Use /stop to "
        "cancel the current run and clear queued messages."
    )


async def post_init(_application: Application) -> None:
    """Start the worker before polling begins."""
    ensure_worker()


async def post_stop(_application: Application) -> None:
    """Cancel the worker and any active pido run during shutdown."""
    global worker_task
    old_worker = worker_task
    worker_task = None
    if old_worker is not None:
        old_worker.cancel()
        await asyncio.gather(old_worker, return_exceptions=True)


def fail(message: str) -> NoReturn:
    """Exit with a configuration error."""
    raise SystemExit(f"pido-telegram: {message}")


def main() -> None:
    if not TOKEN:
        fail("TELEGRAM_BOT_TOKEN is not set")
    if not ALLOWED_USER_ID.isdigit():
        fail("TELEGRAM_ALLOWED_USER_ID must be a numeric Telegram user id")

    application = (
        Application.builder()
        .token(TOKEN)
        .post_init(post_init)
        .post_stop(post_stop)
        .build()
    )
    application.add_handler(CommandHandler("start", start_command))
    application.add_handler(CommandHandler("new", new_command))
    application.add_handler(CommandHandler("stop", stop_command))
    application.add_handler(
        MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message)
    )

    logger.info("starting pido Telegram bot for user %s", ALLOWED_USER_ID)
    application.run_polling(
        allowed_updates=[Update.MESSAGE],
        drop_pending_updates=True,
    )


if __name__ == "__main__":
    main()
