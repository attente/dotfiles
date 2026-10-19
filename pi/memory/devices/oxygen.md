# oxygen

Device-specific memory for the host `oxygen`.
See [../common.md](../common.md) for information shared by all devices.

Last reviewed: 2026-10-19.

## Overview

- Hostname: `oxygen`.
- NixOS state version: `25.11`.
- Home Manager state version: `25.11`.

## Hardware

- Architecture: `x86_64-linux`.
- CPU vendor: AMD.
- GPU driver: `amdgpu`.
- Kernel modules include `lm92` and `nct6775`.
- The kernel command line configures two DisplayPort outputs at `1920x1080@60`.

## Storage and Data

- Root filesystem: btrfs on a LUKS-encrypted device.
- Boot filesystem: vfat.
- Swap: none configured.
- Disk UUIDs and device paths are recorded in `/home/william/.william/etc/oxygen/hardware-configuration.nix`; consult that file when exact identifiers are needed.

## Notes

Record only stable device facts here.
Mark entries as possibly outdated when they can no longer be verified.
