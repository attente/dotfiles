{ lib, pkgs, pkgs-kernel, ... }:

let
  linux_6_18 = pkgs-kernel.linux_6_18.overrideAttrs (old: {
    passthru = (old.passthru or { }) // {
      target = old.passthru.target or "bzImage";
      buildDTBs = old.passthru.buildDTBs or false;
    };
  });
in

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../kolide-falcon
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      editor = false;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  # Keep phosphorus on the same older kernel used by the laptop config.
  boot.kernelPackages = lib.mkForce (pkgs-kernel.linuxPackagesFor linux_6_18);

  boot.tmp.cleanOnBoot = true;

  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "xfs"
    "ntfs"
    "fat"
    "vfat"
    "exfat"
  ];

  hardware.firmware = with pkgs; [
    linux-firmware
    sof-firmware
    alsa-firmware
  ];

  # The pinned kernel comes from a separate nixpkgs input whose kernel package
  # does not expose buildDTBs in the shape expected by this NixOS module set.
  hardware.deviceTree.enable = lib.mkForce false;

  services.udev.packages = [
    pkgs.yubikey-personalization
  ];

  networking = {
    hostName = "phosphorus";
    useDHCP = lib.mkDefault true;
    networkmanager.wifi.powersave = false;
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
