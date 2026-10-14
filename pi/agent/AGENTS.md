# Agent Directives

## Punctuation & Style

- **Trailing newline:** End every text file with a newline.
- **ASCII only:** Use only standard ASCII characters directly printable from a QWERTY keyboard. Do not use em dashes, en dashes, curly quotes, or other special Unicode symbols. Use hyphens, colons, commas, straight quotes, and apostrophes instead.
- **Semantic line breaks:** In Markdown, write one sentence per line and separate paragraphs with a blank line.

## Dependencies & Tooling

- **Idiomatic and standard:** Choose idiomatic, established, well-maintained libraries and SDKs with high community usage and active support. Avoid unmaintained, niche, or redundant packages when standard solutions exist.

## Reading & Output

- **Targeted reads:** For files over 200 lines, use offset/limit or search with `grep`/`rg`. Never read an entire multi-thousand-line file unless explicitly instructed.
- **Quiet commands:** Prefix shell commands with `rtk` when available (for example, `rtk git status`, `rtk pytest`, `rtk npm test`) and pass minimal or quiet flags where possible (for example, `git status -s`, `pytest -q`).
- **Concise responses:** Summarize command output and file edits in one or two sentences. Avoid line-by-line explanations or meta-commentary unless requested.
