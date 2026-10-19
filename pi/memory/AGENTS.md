# Device Memory Instructions

This directory is persistent memory about William's devices and data.
Use it to answer questions and complete tasks that depend on local machine details.

## Public Repository Rules

This is a public repository.
Never record passwords, passphrases, API keys, tokens, private keys, recovery codes, or other credentials.
Never record private personal information, confidential file contents, or anything that would be harmful if published.

## What to Record

Record information that is stable and useful across sessions, such as:

- Hardware and device capabilities.
- Disk, filesystem, and mount layout.
- Installed operating system and configuration management details.
- Stable application and service configuration.
- Locations of important data and backups.
- Known limitations, quirks, and workarounds.

Do not record ephemeral state, such as:

- Current IP addresses, battery levels, temperatures, or resource usage.
- Running processes, open windows, or active sessions.
- Temporary file paths or contents.
- Values that are likely to change after a reboot, application restart, or configuration change.

## Maintaining Accuracy

When a recorded fact stops being true, update it instead of leaving it silently wrong.
If the current state cannot be confirmed, mark the entry as possibly outdated and explain what needs to be checked.
Prefer describing the current configuration over historical details.
Add a short date or "last verified" note when it helps distinguish current facts from older ones.

## Committing Changes

After modifying any memory file, commit the change to the repository.
Stage only the memory files that changed, then create a commit with a concise message that describes the update.
Do not include unrelated working-tree changes in the commit.
If there is nothing to commit because no memory file changed, do not create an empty commit.

Example:

```sh
git -C /home/william/.william/etc add pi/memory
git -C /home/william/.william/etc commit -m "Update pi memory"
```

## Organization

- Before operating with memory, run the `hostname` command to determine the current machine.
- Never assume the hostname from a recorded fact; always confirm it with `hostname` first.
- `common.md` contains information that applies to all devices.
- `devices/<hostname>.md` contains information for one machine.
- Read `common.md` first when a task depends on general local context.
- Read `devices/$(hostname).md` when a task depends on the current machine.
- Consult only the files relevant to the task instead of loading every memory file.
- If the current hostname has no device file, use `common.md` and state that device-specific memory is unavailable.

## Response Style

By default, reply briefly and concisely, as if writing a text message.
Keep answers to the point and omit unnecessary preamble, summaries, and repetition.
If the prompt explicitly asks for more detail, a longer explanation, or a full walkthrough, follow that request and provide the requested depth.

## Writing Style

Use Markdown with one sentence per line.
Keep entries concise, factual, and easy to update.
Use relative links between files in this directory.
