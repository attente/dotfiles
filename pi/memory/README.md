# Pi Memory

Persistent, non-sensitive knowledge about William's devices and data.
This repository is public, so this directory must not contain credentials, private personal information, or other sensitive material.

## Layout

- [common.md](common.md) contains information that applies to all devices.
- [devices/oxygen.md](devices/oxygen.md) contains information specific to oxygen.
- [devices/phosphorus.md](devices/phosphorus.md) contains information specific to phosphorus.
- [AGENTS.md](AGENTS.md) contains instructions for the pi coding agent when it works from this directory.

## Usage

Run `pido` to start pi with this directory as its working directory.
Pass a prompt to ask a question or assign a task:

```sh
pido "What filesystem layout does this machine use?"
pido --print "Summarize the stable hardware details for this host"
```

## Maintenance

Keep information stable and factual.
Do not record ephemeral state such as current IP addresses, battery levels, or running processes.
When a fact changes, update it.
If a fact cannot be verified, mark it as possibly outdated.
