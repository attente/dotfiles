#!/usr/bin/env python3
"""Telegram front-end for pido.

Send a text message to run pido with that message as the prompt. The bot
forwards -p and, unless the conversation was reset with /new, -c. The pido
output is sent back to the same chat. /stop cancels the active run and clears
queued messages. Markdown in the pido output is rendered for Telegram, so
headings, bold and italic text, lists, links, and code blocks appear formatted.
A reply that ends with suggested follow-up actions gets one inline button per
action, and pressing one runs that action as the next prompt. The actions come
from a followups code block requested by FOLLOW_UP_INSTRUCTION, or from a list
under a heading such as "Next steps". That block is removed from the message.
"""

from __future__ import annotations

import asyncio
import html
import logging
import os
import re
import secrets
import signal
from collections import OrderedDict
from dataclasses import dataclass
from typing import NoReturn

from markdown_it import MarkdownIt
from markdown_it.token import Token
from telegram import (
    CallbackQuery,
    Chat,
    InlineKeyboardButton,
    InlineKeyboardMarkup,
    Message,
    Update,
)
from telegram.constants import ChatAction, ParseMode
from telegram.error import BadRequest
from telegram.ext import (
    Application,
    CallbackQueryHandler,
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
# Telegram caps a message at 4096 characters of parsed text. Tags and escaping
# inflate the raw HTML, so chunks are cut well below the cap.
HTML_CHUNK_LIMIT = 3500

MARKDOWN = MarkdownIt("commonmark").enable(["table", "strikethrough"])
TAG_PATTERN = re.compile(r"<[^>]*>")
TAG_NAME_PATTERN = re.compile(r"<\s*/?\s*([A-Za-z0-9-]+)")
LANGUAGE_PATTERN = re.compile(r"[A-Za-z0-9_+#.-]+")
ANSI_PATTERN = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")
VOID_TAGS = frozenset({"br"})
FOLLOW_UP_FENCE_LANGUAGES = frozenset({"followups", "follow-ups", "actions"})
FOLLOW_UP_HEADING_PATTERN = re.compile(
    r"^(next steps?|next actions?|follow[- ]?ups?|suggested actions?"
    r"|possible actions?|recommended actions?|what next|next move)\b",
    re.IGNORECASE,
)
TASK_MARKER_PATTERN = re.compile(r"^\[[ xX]\]\s*")
FOLLOW_UP_FENCE_PATTERN = re.compile(
    r"^(?P<fence>`{3,})[ \t]*(?:followups|follow-ups|actions)[^\n]*\n"
    r"(?P<body>.*?)^(?P=fence)[ \t]*$",
    re.IGNORECASE | re.MULTILINE | re.DOTALL,
)
BLANK_LINES_PATTERN = re.compile(r"\n[ \t]*(?:\n[ \t]*)+")
MAX_FOLLOW_UPS = 8
ACTION_LABEL_LIMIT = 40
ACTION_PROMPT_LIMIT = 500
ACTION_DATA_PREFIX = "act:"
MAX_PENDING_ACTIONS = 256

# Appended to pi's system prompt so follow-up suggestions arrive in a shape the
# bot can turn into buttons. The block is optional and stripped before display.
FOLLOW_UP_INSTRUCTION = (
    "When, and only when, your reply suggests concrete next actions the "
    "user might take, near the end present each action in full as a "
    "numbered 'Next steps' list, then end with a single fenced code "
    "block tagged followups: one very short imperative label per line "
    "(at most five words), at most five lines, one label per listed "
    "action in the same order. The list is for the user to read; each "
    "label becomes a tap-to-run button that sends the label back as the "
    "next prompt, so it must stand alone. Omit both the list and the "
    "block when there are no such actions, and never mention or explain "
    "them."
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
logger = logging.getLogger("pido-telegram")


@dataclass(slots=True)
class QueueItem:
    """A queued message, follow-up shortcut, or /new marker."""

    update_id: int
    chat_id: int
    message: Message
    prompt: str | None


pending_actions: OrderedDict[tuple[int, str], str] = OrderedDict()


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


def escape_text(text: str) -> str:
    """Escape text for Telegram's HTML parse mode."""
    return html.escape(text, quote=False)


def attribute(token: Token, name: str) -> str:
    """Read one attribute from a markdown-it token."""
    attrs = token.attrs
    if not attrs:
        return ""
    if isinstance(attrs, dict):
        value = attrs.get(name, "")
    else:
        value = dict(attrs).get(name, "")
    return str(value or "")


def render_inline(children: list[Token]) -> str:
    """Render markdown-it inline tokens to the Telegram HTML subset."""
    parts: list[str] = []
    for token in children:
        kind = token.type
        content = token.content
        if kind == "text":
            parts.append(escape_text(content))
        elif kind == "code_inline":
            parts.append(f"<code>{escape_text(content)}</code>")
        elif kind == "strong_open":
            parts.append("<b>")
        elif kind == "strong_close":
            parts.append("</b>")
        elif kind == "em_open":
            parts.append("<i>")
        elif kind == "em_close":
            parts.append("</i>")
        elif kind == "s_open":
            parts.append("<s>")
        elif kind == "s_close":
            parts.append("</s>")
        elif kind == "link_open":
            href = html.escape(attribute(token, "href"), quote=True)
            parts.append(f'<a href="{href}">')
        elif kind == "link_close":
            parts.append("</a>")
        elif kind == "image":
            src = attribute(token, "src")
            alt = content or src
            parts.append(
                f'<a href="{html.escape(src, quote=True)}">'
                f"{escape_text(alt)}</a>"
            )
        elif kind in ("softbreak", "hardbreak"):
            parts.append("\n")
        elif kind == "html_inline" or content:
            parts.append(escape_text(content))
    return "".join(parts)


def inline_plain_text(children: list[Token]) -> str:
    """Render inline tokens as plain text, for table cell alignment."""
    return html.unescape(TAG_PATTERN.sub("", render_inline(children)))


class TelegramHtmlBuilder:
    """Accumulate Telegram HTML from a markdown-it block token stream."""

    def __init__(self) -> None:
        self.buffer = ""
        self.lists: list[list[int | str]] = []
        self.item_started = False

    def text(self, value: str) -> None:
        self.buffer += value

    def block_break(self) -> None:
        """Ensure the buffer ends with a blank line."""
        if not self.buffer or self.buffer.endswith("\n\n"):
            return
        if self.buffer.endswith("\n"):
            self.buffer += "\n"
        else:
            self.buffer += "\n\n"


def read_table(tokens: list[Token], index: int) -> tuple[list[list[str]], int]:
    """Collect the rows of the table starting at index."""
    rows: list[list[str]] = []
    row: list[str] | None = None
    cursor = index + 1
    while cursor < len(tokens) and tokens[cursor].type != "table_close":
        token = tokens[cursor]
        if token.type == "tr_open":
            row = []
        elif token.type == "tr_close":
            if row is not None:
                rows.append(row)
            row = None
        elif token.type == "inline" and row is not None:
            row.append(inline_plain_text(token.children or []))
        cursor += 1
    return rows, cursor


def render_table(rows: list[list[str]]) -> str:
    """Render a Markdown table as an aligned monospace block."""
    columns = max((len(row) for row in rows), default=0)
    if columns == 0:
        return ""
    widths = [0] * columns
    for row in rows:
        for column, cell in enumerate(row):
            widths[column] = max(widths[column], len(cell))
    lines: list[str] = []
    for row_index, row in enumerate(rows):
        cells = [
            (row[column] if column < len(row) else "").ljust(widths[column])
            for column in range(columns)
        ]
        lines.append(" | ".join(cells).rstrip())
        if row_index == 0 and len(rows) > 1:
            lines.append("-+-".join("-" * width for width in widths))
    return f"<pre>{escape_text(chr(10).join(lines))}</pre>"


def markdown_to_telegram_html(text: str) -> str:
    """Convert Markdown to the HTML subset that Telegram accepts."""
    tokens = MARKDOWN.parse(ANSI_PATTERN.sub("", text))
    builder = TelegramHtmlBuilder()
    index = 0
    total = len(tokens)
    while index < total:
        token = tokens[index]
        kind = token.type
        if kind == "inline":
            builder.text(render_inline(token.children or []))
        elif kind == "paragraph_open":
            if builder.lists and builder.item_started:
                builder.item_started = False
            elif builder.buffer and not builder.buffer.endswith("\n"):
                builder.text("\n\n")
        elif kind == "paragraph_close":
            if builder.lists:
                if not builder.buffer.endswith("\n"):
                    builder.text("\n")
            else:
                builder.block_break()
        elif kind == "heading_open":
            if builder.buffer and not builder.buffer.endswith("\n\n"):
                builder.block_break()
            builder.text("<b>")
        elif kind == "heading_close":
            builder.text("</b>")
            builder.block_break()
        elif kind == "bullet_list_open":
            builder.lists.append(["bullet", 0])
        elif kind == "ordered_list_open":
            start = attribute(token, "start")
            builder.lists.append(
                ["ordered", int(start) if start.isdigit() else 1]
            )
        elif kind in ("bullet_list_close", "ordered_list_close"):
            if builder.lists:
                builder.lists.pop()
            if not builder.lists:
                builder.block_break()
        elif kind == "list_item_open":
            if builder.buffer and not builder.buffer.endswith("\n"):
                builder.text("\n")
            builder.text("  " * max(len(builder.lists) - 1, 0))
            if builder.lists and builder.lists[-1][0] == "ordered":
                number = int(builder.lists[-1][1])
                builder.text(f"{number}. ")
                builder.lists[-1][1] = number + 1
            else:
                builder.text("- ")
            builder.item_started = True
        elif kind == "list_item_close":
            if builder.buffer and not builder.buffer.endswith("\n"):
                builder.text("\n")
            builder.item_started = False
        elif kind == "blockquote_open":
            builder.block_break()
            builder.text("<blockquote>")
        elif kind == "blockquote_close":
            if not builder.buffer.endswith("\n"):
                builder.text("\n")
            builder.text("</blockquote>")
            builder.block_break()
        elif kind in ("fence", "code_block"):
            code = token.content.rstrip("\n")
            language = ""
            if kind == "fence":
                language = token.info.strip().split(" ", 1)[0]
            if language and LANGUAGE_PATTERN.fullmatch(language):
                builder.text(
                    f'<pre><code class="language-{language}">'
                    f"{escape_text(code)}</code></pre>"
                )
            else:
                builder.text(f"<pre>{escape_text(code)}</pre>")
            builder.block_break()
        elif kind == "hr":
            builder.block_break()
            builder.text("---")
            builder.block_break()
        elif kind == "html_block":
            escaped = escape_text(token.content.strip())
            if escaped:
                builder.text(f"<pre>{escaped}</pre>")
                builder.block_break()
        elif kind == "table_open":
            rows, index = read_table(tokens, index)
            table = render_table(rows)
            if table:
                builder.block_break()
                builder.text(table)
                builder.block_break()
        index += 1
    return re.sub(
        r"\n{3,}",
        "\n\n",
        re.sub(r"\n+</blockquote>", "\n</blockquote>", builder.buffer),
    ).replace("<blockquote>\n\n", "<blockquote>").strip()


def tag_name(tag: str) -> str:
    """Return the lowercased element name of an HTML tag."""
    match = TAG_NAME_PATTERN.match(tag)
    return match.group(1).lower() if match else ""


def open_tag_stack(text: str) -> list[str]:
    """Return the tags still open at the end of the given HTML."""
    stack: list[str] = []
    for match in TAG_PATTERN.finditer(text):
        tag = match.group(0)
        name = tag_name(tag)
        if not name or name in VOID_TAGS:
            continue
        if tag.startswith("</"):
            if stack:
                stack.pop()
        elif not tag.endswith("/>"):
            stack.append(tag)
    return stack


def split_html(text: str, limit: int = HTML_CHUNK_LIMIT) -> list[str]:
    """Split HTML into balanced chunks without cutting through a tag."""
    chunks: list[str] = []
    prefix = ""
    position = 0
    while position < len(text):
        budget = limit - len(prefix)
        if budget <= 0:
            prefix = ""
            budget = limit
        window_end = position + budget
        if window_end >= len(text):
            piece = prefix + text[position:]
            if piece.strip():
                chunks.append(piece)
            break

        newline = -1
        space = -1
        cursor = position
        while cursor < window_end:
            char = text[cursor]
            if char == "<":
                end = text.find(">", cursor)
                cursor = window_end if end == -1 else end + 1
                continue
            if char == "\n":
                newline = cursor
            elif char == " ":
                space = cursor
            cursor += 1

        threshold = position + budget // 2
        if newline >= threshold:
            split_at = newline
        elif space >= threshold:
            split_at = space
        else:
            split_at = cursor
        if split_at <= position:
            split_at = window_end

        piece = prefix + text[position:split_at]
        stack = open_tag_stack(piece)
        excess = len(piece) + sum(len(tag) + 3 for tag in stack) - limit
        if excess > 0:
            # Closing tags are appended after the body, so pull the split back
            # to the nearest break until the finished chunk fits, never
            # landing inside a tag.
            cut = split_at - excess
            for separator in ("\n", " "):
                candidate = text.rfind(separator, position, cut)
                if candidate >= position + budget // 3:
                    cut = candidate
                    break
            while cut > position and text.rfind(
                "<", position, cut
            ) > text.rfind(">", position, cut):
                cut = text.rfind("<", position, cut)
            if cut > position:
                split_at = cut
                piece = prefix + text[position:split_at]
                stack = open_tag_stack(piece)
        if piece.strip():
            closing = "".join(f"</{tag_name(tag)}>" for tag in reversed(stack))
            chunks.append(piece + closing)
        prefix = "".join(stack)
        position = split_at
        while position < len(text) and text[position] in " \n":
            position += 1
    return chunks


def html_to_plain(text: str) -> str:
    """Strip Telegram HTML markup for a plain-text fallback."""
    return html.unescape(TAG_PATTERN.sub("", text))


def extract_follow_ups(text: str) -> list[str]:
    """Return follow-up actions listed under a suggestion heading."""
    tokens = MARKDOWN.parse(ANSI_PATTERN.sub("", text))
    actions: list[str] = []
    active = False
    awaiting_heading = False
    list_depth = 0
    item_parts: list[str] | None = None
    item_taken = False

    def flush_item() -> None:
        nonlocal item_parts
        if item_parts is None:
            return
        item = " ".join(part for part in item_parts if part.strip())
        item = TASK_MARKER_PATTERN.sub("", item).strip()
        if item:
            actions.append(item)
        item_parts = None

    for token in tokens:
        kind = token.type
        if kind == "heading_open":
            flush_item()
            awaiting_heading = True
        elif kind == "inline" and awaiting_heading:
            heading = inline_plain_text(token.children or []).strip()
            active = bool(FOLLOW_UP_HEADING_PATTERN.match(heading))
            awaiting_heading = False
        elif kind in ("bullet_list_open", "ordered_list_open"):
            list_depth += 1
        elif kind in ("bullet_list_close", "ordered_list_close"):
            flush_item()
            list_depth = max(list_depth - 1, 0)
        elif kind == "list_item_open" and active and list_depth == 1:
            item_parts = []
            item_taken = False
        elif kind == "inline" and item_parts is not None and not item_taken:
            item_parts.append(inline_plain_text(token.children or []))
            item_taken = True
        elif kind == "list_item_close" and active and list_depth == 1:
            flush_item()
        elif kind == "fence":
            language = token.info.strip().split(" ", 1)[0].lower()
            if language in FOLLOW_UP_FENCE_LANGUAGES:
                for line in token.content.splitlines():
                    line = line.strip().lstrip("-* ").strip()
                    if line:
                        actions.append(line)

    unique = list(dict.fromkeys(actions))
    return unique[:MAX_FOLLOW_UPS]


def split_follow_ups(text: str) -> tuple[str, list[str]]:
    """Remove follow-up fence blocks and return the actions they list."""
    actions: list[str] = []
    removed = False

    def take(match: re.Match[str]) -> str:
        nonlocal removed
        removed = True
        for line in match.group("body").splitlines():
            line = line.strip().lstrip("-* ").strip()
            if line:
                actions.append(line)
        return ""

    cleaned = FOLLOW_UP_FENCE_PATTERN.sub(take, text)
    if removed:
        cleaned = BLANK_LINES_PATTERN.sub("\n\n", cleaned)
    if not actions:
        actions = extract_follow_ups(cleaned)
    unique = list(dict.fromkeys(actions))
    return cleaned.strip(), unique[:MAX_FOLLOW_UPS]


def action_label(prompt: str) -> str:
    """Build a short button label from a follow-up action."""
    label = " ".join(prompt.split())
    if len(label) <= ACTION_LABEL_LIMIT:
        return label
    return label[: ACTION_LABEL_LIMIT - 3].rstrip() + "..."


def remember_action(chat_id: int, prompt: str) -> str:
    """Store a follow-up prompt and return its short callback token."""
    token = secrets.token_hex(4)
    pending_actions[(chat_id, token)] = prompt[:ACTION_PROMPT_LIMIT]
    while len(pending_actions) > MAX_PENDING_ACTIONS:
        pending_actions.popitem(last=False)
    return token


def take_action(chat_id: int, token: str) -> str | None:
    """Consume a stored follow-up prompt."""
    return pending_actions.pop((chat_id, token), None)


def follow_up_keyboard(
    chat_id: int, prompts: list[str]
) -> InlineKeyboardMarkup:
    """Build one button per follow-up action."""
    rows = [
        [
            InlineKeyboardButton(
                action_label(prompt),
                callback_data=(
                    ACTION_DATA_PREFIX + remember_action(chat_id, prompt)
                ),
            )
        ]
        for prompt in prompts
    ]
    return InlineKeyboardMarkup(rows)


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
    args = [PIDO_PATH, "-p", "-s", FOLLOW_UP_INSTRUCTION]
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


async def send_chunk(
    message: Message,
    chat: Chat,
    text: str,
    parse_mode: str | None,
    first: bool,
    reply_markup: InlineKeyboardMarkup | None = None,
) -> None:
    """Send one chunk, replying to the prompt for the first one."""
    if first:
        await message.reply_text(
            text, parse_mode=parse_mode, reply_markup=reply_markup
        )
    else:
        await chat.send_message(
            text, parse_mode=parse_mode, reply_markup=reply_markup
        )


async def reply_with_result(message: Message, text: str) -> None:
    """Send a result as formatted HTML, split where Telegram requires it."""
    visible, follow_ups = split_follow_ups(text)
    chunks = split_html(markdown_to_telegram_html(visible))
    if not chunks:
        if follow_ups:
            chunks = ["Suggested follow-ups:"]
        else:
            plain = html_to_plain(visible)[:REPLY_CHUNK_LIMIT]
            chunks = [plain or "pido produced no output."]
    keyboard = (
        follow_up_keyboard(message.chat_id, follow_ups) if follow_ups else None
    )
    for index, chunk in enumerate(chunks):
        first = index == 0
        last = index == len(chunks) - 1
        markup = keyboard if last else None
        try:
            await send_chunk(
                message, message.chat, chunk, ParseMode.HTML, first, markup
            )
        except BadRequest:
            logger.warning("Telegram rejected HTML output, sending plain text")
            plain = html_to_plain(chunk)[:REPLY_CHUNK_LIMIT]
            await send_chunk(
                message, message.chat, plain, None, first, markup
            )
        if not last:
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
        "cancel the current run and clear queued messages. When a reply ends "
        "with suggested follow-ups, tap a button under it to run that action."
    )


async def answer_callback(
    query: CallbackQuery, text: str | None = None
) -> None:
    """Answer a callback query, ignoring expired queries."""
    try:
        await query.answer(text)
    except BadRequest:
        logger.debug("could not answer callback query", exc_info=True)


async def action_callback(
    update: Update, _context: ContextTypes.DEFAULT_TYPE
) -> None:
    """Run the follow-up action behind a pressed shortcut button."""
    query = update.callback_query
    if query is None:
        return

    message = query.message
    if not is_allowed(update) or message is None:
        await answer_callback(query, "Not authorized.")
        return

    data = query.data or ""
    prompt = None
    if data.startswith(ACTION_DATA_PREFIX):
        prompt = take_action(message.chat_id, data[len(ACTION_DATA_PREFIX) :])

    try:
        await query.edit_message_reply_markup(reply_markup=None)
    except BadRequest:
        logger.debug("could not clear shortcut buttons", exc_info=True)

    if prompt is None:
        await answer_callback(query, "This shortcut has expired.")
        return

    await answer_callback(query)
    chosen = await message.reply_text(prompt)
    await prompt_queue.put(
        QueueItem(update.update_id, message.chat_id, chosen, prompt)
    )
    ensure_worker()


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
    application.add_handler(CallbackQueryHandler(action_callback))
    application.add_handler(
        MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message)
    )

    logger.info("starting pido Telegram bot for user %s", ALLOWED_USER_ID)
    application.run_polling(
        allowed_updates=[Update.MESSAGE, Update.CALLBACK_QUERY],
        drop_pending_updates=True,
    )


if __name__ == "__main__":
    main()
