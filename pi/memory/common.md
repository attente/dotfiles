# Common Information

Information in this file applies to all devices unless a device-specific file overrides it.

Last reviewed: 2026-10-20.

## User and Environment

- Username: `william`.
- Home directory: `/home/william`.
- Time zone: `America/Toronto`.
- Operating system: NixOS.
- Configuration repository: `/home/william/.william/etc`.
- The repository is a NixOS flake that defines the hosts `oxygen` and `phosphorus`.
- Shared system configuration is in `/home/william/.william/etc/configuration.nix`.
- Host-specific hardware configuration is in `/home/william/.william/etc/<hostname>/hardware-configuration.nix`.
- Host-specific settings are defined in `/home/william/.william/etc/flake.nix`.

## Services

- OpenSSH is enabled.
- Tailscale is enabled.
- Avahi is enabled.
- `fwupd` is enabled.
- The SSH agent is enabled for user sessions.

## Data and Configuration

- User configuration in this repository lives under `/home/william/.william/etc`.
- Secrets are managed outside this public memory directory.
- Do not copy values from `/home/william/.william/etc/secrets.nix` or password stores into memory files.

## Herdr

- If asked to do something with Herdr and Herdr is not running, start it as a detached headless server with `herdr server`.
- Do not launch the bare `herdr` TUI from an automated shell; it launches or attaches the interactive TUI, which is for the user's own terminal.
- For an incoming request, first check Herdr's existing workspaces and agents (for example, `herdr workspace list` and `herdr agent list`) for work related to the request.
- Prefer delegating project-specific work to an active agent already working in that repository, using `herdr agent prompt <name> ...`; avoid duplicating the work in the caller session when a suitable agent is available.
- If none is related, create a workspace at the correct project directory and start a pi agent there.
- Start the Herdr server with `herdr server` first if it is not already running.

## Notes

Add new common facts under the most relevant section.
Move a fact to a device file if it applies to only one machine.
