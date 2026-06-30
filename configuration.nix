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

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    extraDependencyGroups = [ "messaging" ];
    environmentFiles = [ "/var/lib/hermes/env" ];
    createUser = false;
    user = "william";
    group = "users";
    container = {
      enable = true;
      backend = "podman";
      hostUsers = [ "william" ];
      extraVolumes = [
        "/run/user/1000:/run/user/1000:ro"
        "/run/user/1000/podman/podman.sock:/var/run/docker.sock"
        "/home/william/.config/git/config:/home/hermes/.config/git/config"
        "/home/william/.config/gh:/home/hermes/.config/gh"
        "/home/william/.config/codex:/home/hermes/.codex"
        "/home/william/.claude.json:/home/hermes/.claude.json"
        "/home/william/.claude:/home/hermes/.claude"
        "/home/william/hermes:/data/workspace"
      ];
      extraOptions = [
        "--label=forced-refresh=refresh-4" # bump to force refresh
      ];
    };
    settings = {
      model = {
        provider = "openrouter";
        default = "deepseek/deepseek-v4-flash";
      };
      privacy.redact_pii = true;
      approvals = {
        mode = "off";
        cron_mode = "approve";
        mcp_reload_confirm = false;
        destructive_slash_confirm = false;
      };
      worktree = true;
      terminal = {
        cwd = "/data/workspace";
        shell = "zsh";
      };
      telegram = {
        unauthorized_dm_behavior = "ignore";
        allowed_chats = [ "__no_groups__" ];
        guest_mode = false;
        require_mention = true;
        exclusive_bot_mentions = true;
        disable_topic_auto_rename = true;
        reactions = true;
      };
    };
  };
}
