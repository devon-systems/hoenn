# Verdanturf

MacBook Air M2 13-inch running NixOS with the Asahi Linux kernel and firmware
support.

## Installation handoff

The Asahi installer creates a machine-specific EFI system partition and places
Apple's non-redistributable peripheral firmware on it. Before installing this
configuration:

1. Follow the nixos-apple-silicon UEFI installation guide and format the root
   filesystem with the `nixos` label.
2. Mount the EFI system partition at `/mnt/boot` as described by that guide.
3. Copy `/mnt/boot/vendorfw/firmware.cpio` into a local, untracked directory and
   temporarily set `hardware.asahi.peripheralFirmwareDirectory` to that path
   for the machine-local installation build.
4. Add the generated `/boot` filesystem entry to `asahi.nix` after the installer
   reveals its UUID or PARTUUID.

The committed configuration disables peripheral firmware extraction because CI
cannot access or redistribute that firmware. The system output remains buildable
on the Ubuntu ARM runner.
