# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

let secrets = import /etc/nixos/secrets.nix; in

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "hydrogen"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlp2s0.useDHCP = true;

  networking.nameservers = [
    "45.90.28.212"
    "45.90.30.212"
  ];

  networking.resolvconf.extraConfig = ''
    name_server_blacklist='192.168.*'
  '';

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  services.logind.lidSwitch = "ignore";

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.mutableUsers = false;

  users.defaultUserShell = pkgs.zsh;

  users.users.root.hashedPassword = secrets.users.root.hashedPassword;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.william = {
    uid = 1000;
    description = "William Hua";
    isNormalUser = true;
    hashedPassword = secrets.users.william.hashedPassword;
    openssh.authorizedKeys.keys = secrets.keys;
    extraGroups = [
      "docker"
      "video"
      "wheel"
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    docker-compose
    git
    neovim
  ];

  environment.shellAliases = {
    vi = "nvim";
  };

  environment.shellInit = ''
    export EDITOR=nvim
    export VISUAL=nvim
  '';

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs.light.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
    };
  };

  # List services that you want to enable:

  services.nextdns = {
    enable = true;
    arguments = [
      "-listen" "localhost:5300"
      "-cache-size" "10MB"
      "-forwarder" "https://firefox.dns.nextdns.io"
      "-log-queries"
    ];
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  virtualisation.docker.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 53 80 443 ];
  networking.firewall.allowedUDPPorts = [ 53 67 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}

