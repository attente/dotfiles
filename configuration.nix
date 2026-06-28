{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./common.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.kernelModules = [
    "amdgpu"
    "lm92"
    "nct6775"
  ];

  boot.kernelParams = [
    "video=DP-1:1920x1080@60"
    "video=DP-2:1920x1080@60"
  ];

  networking.hostName = "oxygen";
}
