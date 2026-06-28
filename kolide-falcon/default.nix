# Kolide + CrowdStrike Falcon setup for NixOS.
#
# Before switching phosphorus to this config, keep these state files:
#
#   /etc/kolide-k2/secret
#   /etc/falcon-sensor.env
#   /opt/CrowdStrike
#
# The Falcon service copies package files into /opt/CrowdStrike without
# deleting unknown runtime state. In particular, falconstore contains the
# Agent ID (AID); losing it can cause the sensor to re-register as a new host.
{
  inputs,
  pkgs,
  lib,
  ...
}:

let
  falconVersion = "7.31.0-18410";
  falconArch = "amd64";

  falconSrc = pkgs.requireFile {
    name = "falcon-sensor_${falconVersion}_${falconArch}.deb";
    sha256 = "dc2b2bbad474e36f9227292f738266bcc063ab1abdd1197f3d1af54c95fa6a04";
    message = ''
      CrowdStrike Falcon Sensor .deb is required but not found in the nix store.

      Add the bundled copy to the store:

        nix-store --add-fixed sha256 ./kolide-falcon/falcon-sensor_${falconVersion}_${falconArch}.deb
    '';
  };

  falcon-sensor = pkgs.stdenv.mkDerivation {
    pname = "falcon-sensor";
    version = falconVersion;
    src = falconSrc;

    nativeBuildInputs = [
      pkgs.dpkg
      pkgs.autoPatchelfHook
    ];
    buildInputs = [ pkgs.zlib ];
    sourceRoot = ".";

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      cp -r . $out
    '';

    meta = with lib; {
      description = "CrowdStrike Falcon Sensor";
      homepage = "https://www.crowdstrike.com/";
      license = licenses.unfree;
      platforms = platforms.linux;
    };
  };

  falcon = pkgs.buildFHSEnv {
    name = "falcon-fhs";
    targetPkgs = pkgs: [
      pkgs.libnl
      pkgs.openssl
      pkgs.zlib
    ];

    extraInstallCommands = ''
      ln -s ${falcon-sensor}/* $out/
    '';

    runScript = "bash";
  };

  falconInitScript = pkgs.writeShellScript "init-falcon" ''
    set -euo pipefail

    if [ ! -r /etc/falcon-sensor.env ]; then
      echo "missing /etc/falcon-sensor.env" >&2
      exit 1
    fi

    install -d -m 0770 /opt/CrowdStrike

    # Do not use --delete here: Falcon keeps identity and runtime state under
    # /opt/CrowdStrike, and future sensor versions may add more state files.
    ${pkgs.rsync}/bin/rsync -a \
      "${falcon}/opt/CrowdStrike/" /opt/CrowdStrike/

    chown -R root:root /opt/CrowdStrike

    . /etc/falcon-sensor.env

    ${falcon}/bin/falcon-fhs -c "/opt/CrowdStrike/falconctl -s -f --cid=\"$FALCON_CID\""
    ${falcon}/bin/falcon-fhs -c "/opt/CrowdStrike/falconctl -g --cid"
  '';
in
{
  nixpkgs.config.allowUnfree = true;

  imports = [
    "${inputs.kolide-nix-agent}/modules/kolide-launcher"
  ];

  services.kolide-launcher.enable = true;

  # Add dpkg to Kolide's path for osquery deb_packages checks.
  systemd.services.kolide-launcher.path = with pkgs; [ dpkg ];

  systemd.tmpfiles.rules = [
    "d /etc/kolide-k2 0755 root root -"
    "z /etc/kolide-k2/secret 0600 root root -"
    "d /var/lib/dpkg 0755 root root -"
    "f /var/lib/dpkg/status 0644 root root - Package: falcon-sensor\\nStatus: install ok installed\\nPriority: optional\\nSection: misc\\nInstalled-Size: 0\\nMaintainer: CrowdStrike\\nArchitecture: amd64\\nVersion: ${falconVersion}\\nDescription: CrowdStrike Falcon Sensor (shim for Kolide/osquery on NixOS)\\n"
    "d /opt/CrowdStrike 0770 root root -"
  ];

  systemd.services.falcon-sensor = {
    description = "CrowdStrike Falcon Sensor";
    wantedBy = [ "multi-user.target" ];

    unitConfig.DefaultDependencies = false;
    after = [ "local-fs.target" ];
    conflicts = [ "shutdown.target" ];
    before = [
      "sysinit.target"
      "shutdown.target"
    ];

    serviceConfig = {
      Type = "forking";
      PIDFile = "/run/falcond.pid";
      ExecStartPre = falconInitScript;
      ExecStart = "${falcon}/bin/falcon-fhs -c \"/opt/CrowdStrike/falcond\"";

      Restart = "on-failure";
      RestartSec = "15s";
      StartLimitIntervalSec = 0;

      TimeoutStopSec = "60s";
      KillMode = "process";
      Delegate = true;
    };
  };
}
