# phosphorus

Device-specific memory for the host `phosphorus`.
See [../common.md](../common.md) for information shared by all devices.

Last reviewed: 2026-10-19.

## Overview

- Hostname: `phosphorus`.
- NixOS state version: `26.05`.
- Home Manager state version: `26.05`.
- The host uses the latest Linux kernel package set.

## Hardware

- Architecture: `x86_64-linux`.
- CPU vendor: AMD.
- TLP battery charge thresholds are configured to start charging at 80 percent and stop at 90 percent.

## Storage and Data

- Root, `/home`, and `/nix` use btrfs subvolumes on a single LUKS-encrypted device.
- Boot filesystem: vfat.
- Swap: none configured.
- Disk UUIDs and device paths are recorded in `/home/william/.william/etc/phosphorus/hardware-configuration.nix`; consult that file when exact identifiers are needed.

## Notes

Record only stable device facts here.
Mark entries as possibly outdated when they can no longer be verified.
