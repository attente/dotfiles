{ pkgs, lib, ... }:

let
  home = "/home/william";
  python = pkgs.python3.withPackages (
    ps: [ ps.python-telegram-bot ps.markdown-it-py ]
  );
  botScript = pkgs.writeText "pido-telegram-bot.py"
    (builtins.readFile ./pido-telegram.py);
  runtimePath = lib.concatStringsSep ":" [
    "${home}/.william/etc/bin"
    "${home}/.cargo/bin"
    "${home}/go/bin"
    "${home}/.npm/bin"
    "${home}/.local/share/pnpm/bin"
    "${home}/.nix-profile/bin"
    "/run/wrappers/bin"
    "/var/lib/flatpak/exports/bin"
    "/run/current-system/sw/bin"
  ];
in
{
  # The token and allowed user ID live in /etc/pido-telegram.env, which is not
  # managed by Nix so secrets do not end up in the Nix store. The file must
  # contain:
  #
  #   TELEGRAM_BOT_TOKEN=...
  #   TELEGRAM_ALLOWED_USER_ID=...
  #
  # It is read by systemd as root before the service drops to william, so it
  # can be owned by root with mode 0600.
  systemd.services.pido-telegram = {
    description = "Telegram bot that runs pido";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    unitConfig = {
      ConditionPathExists = "/etc/pido-telegram.env";
    };

    environment = {
      HOME = home;
      PYTHONUNBUFFERED = "1";
      PIDO_PATH = "${home}/.william/etc/bin/pido";
      PATH = lib.mkForce runtimePath;
    };

    serviceConfig = {
      Type = "simple";
      User = "william";
      Group = "users";
      WorkingDirectory = home;
      EnvironmentFile = "/etc/pido-telegram.env";
      ExecStart = "${python}/bin/python3 ${botScript}";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStopSec = 30;
      KillMode = "control-group";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };
}
