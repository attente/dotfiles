# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

let secrets = import /etc/nixos/secrets.nix; in

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      <home-manager/nixos>
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
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

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 65536;
  };

  networking.hostName = "oxygen"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlp4s0.useDHCP = true;

  hardware.bluetooth.enable = true;

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      cantarell-fonts
      nerd-fonts.noto
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      noto-fonts-extra
      roboto
    ];
  };

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
  ];

  environment.shellAliases = {
    nix-shell = "nix-shell --command zsh";
    vi = "nvim";
  };

  environment.shellInit = ''
    export EDITOR=nvim
    export VISUAL=nvim
  '';

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellInit = "DISABLE_MAGIC_FUNCTIONS=true";
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
    };
  };

  programs.sway = {
    enable = true;

    extraPackages = with pkgs; [
      grim
      mako
      qt5.qtwayland
      (redshift.overrideAttrs (oldAttrs: {
        src = fetchFromGitHub {
          owner = "minus7";
          repo = "redshift";
          rev = "7da875d34854a6a34612d5ce4bd8718c32bec804";
          sha256 = "0nbkcw3avmzjg1jr1g9yfpm80kzisy55idl09b6wvzv2sz27n957";
          fetchSubmodules = true;
        };
      }))
      slurp
      swaybg
      swayidle
      swaylock
      (waybar.override {
        pulseSupport = true;
      })
      wf-recorder
      wl-clipboard
      wofi
      xwayland
    ];

    extraSessionCommands = ''
      export XDG_CURRENT_DESKTOP=sway
      export XDG_SESSION_TYPE=wayland
      export GDK_BACKEND=wayland
      export QT_QPA_PLATFORM=wayland
    '';
  };

  programs.ssh.startAgent = true;

  programs.light.enable = true;

  # List services that you want to enable:

  services.tlp = {
    enable = true;

    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 50;
    };
  };

  services.fwupd.enable = true;

  services.logind.extraConfig = ''
    RuntimeDirectoryInodesMax=1000000000
    RuntimeDirectorySize=25%
  '';

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      userServices = true;
      addresses = true;
      domain = true;
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  services.gvfs.enable = true;

  services.pcscd.enable = true;

  services.openvpn.servers = {
    canada = {
      autoStart = false;
      updateResolvConf = true;
      config = ''
        # ==============================================================================
        # Copyright (c) 2016-2020 Proton Technologies AG (Switzerland)
        # Email: contact@protonvpn.com
        #
        # The MIT License (MIT)
        #
        # Permission is hereby granted, free of charge, to any person obtaining a copy
        # of this software and associated documentation files (the "Software"), to deal
        # in the Software without restriction, including without limitation the rights
        # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        # copies of the Software, and to permit persons to whom the Software is
        # furnished to do so, subject to the following conditions:
        #
        # The above copyright notice and this permission notice shall be included in all
        # copies or substantial portions of the Software.
        #
        # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR # OTHERWISE, ARISING
        # FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
        # IN THE SOFTWARE.
        # ==============================================================================

        # If you are a paying user you can also enable the ProtonVPN ad blocker (NetShield) or Moderate NAT:
        # Use: "v4vP8JZKxL4OXJMjcFISwwaj+f1" as username to enable anti-malware filtering
        # Use: "v4vP8JZKxL4OXJMjcFISwwaj+f2" as username to additionally enable ad-blocking filtering
        # Use: "v4vP8JZKxL4OXJMjcFISwwaj+nr" as username to enable Moderate NAT
        # Note that you can combine the "+nr" suffix with other suffixes.

        client
        dev tun
        proto udp

        remote 169.150.204.44 5060
        remote 178.249.214.65 80
        remote 169.150.204.44 80
        remote 169.150.204.44 1194
        remote 37.120.237.178 51820
        remote 37.120.205.82 51820
        remote 172.83.40.66 80
        remote 172.83.40.66 4569
        remote 66.115.146.162 51820
        remote 178.249.214.65 5060
        remote 37.120.237.178 1194
        remote 86.106.90.98 1194
        remote 86.106.90.98 80
        remote 178.249.214.65 51820
        remote 37.120.205.82 1194
        remote 66.115.146.162 80
        remote 86.106.90.98 51820
        remote 37.120.237.170 5060
        remote 37.120.237.170 4569
        remote 66.115.146.162 5060
        remote 169.150.204.44 5060
        remote 37.120.205.82 5060
        remote 66.115.146.162 51820
        remote 178.249.214.65 1194
        remote 178.249.214.65 80
        remote 172.83.40.66 1194
        remote 169.150.204.44 51820
        remote 178.249.214.65 4569
        remote 178.249.214.65 4569
        remote 37.120.205.82 4569
        remote 66.115.146.162 1194
        remote 37.120.237.170 80
        remote 66.115.146.162 4569
        remote 169.150.204.44 80
        remote 169.150.204.44 4569
        remote 169.150.204.44 1194
        remote 178.249.214.65 51820
        remote 66.115.146.162 4569
        remote 178.249.214.65 5060
        remote 86.106.90.98 5060
        remote 66.115.146.162 80
        remote 37.120.237.178 5060
        remote 37.120.237.170 1194
        remote 178.249.214.65 80
        remote 66.115.146.162 1194
        remote 178.249.214.65 4569
        remote 172.83.40.66 51820
        remote 37.120.237.178 4569
        remote 178.249.214.65 5060
        remote 178.249.214.65 1194
        remote 37.120.205.82 80
        remote 169.150.204.44 51820
        remote 169.150.204.44 4569
        remote 178.249.214.65 51820
        remote 66.115.146.162 5060
        remote 178.249.214.65 1194
        remote 37.120.237.178 80
        remote 172.83.40.66 5060
        remote 86.106.90.98 4569
        remote 37.120.237.170 51820
        server-poll-timeout 20

        remote-random
        resolv-retry infinite
        nobind

        # The following setting is only needed for old OpenVPN clients compatibility. New clients
        # automatically negotiate the optimal cipher.
        cipher AES-256-CBC

        auth SHA512
        verb 3

        setenv CLIENT_CERT 0
        tun-mtu 1500
        tun-mtu-extra 32
        mssfix 1450
        persist-key
        persist-tun

        reneg-sec 0

        remote-cert-tls server
        auth-user-pass
        pull
        fast-io

        script-security 2
        # up /etc/openvpn/update-resolv-conf
        # down /etc/openvpn/update-resolv-conf

        <ca>
        -----BEGIN CERTIFICATE-----
        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
        A1gTTlpi7A==
        -----END CERTIFICATE-----
        </ca>

        key-direction 1
        <tls-auth>
        # 2048 bit OpenVPN static key
        -----BEGIN OpenVPN Static key V1-----
        6acef03f62675b4b1bbd03e53b187727
        423cea742242106cb2916a8a4c829756
        3d22c7e5cef430b1103c6f66eb1fc5b3
        75a672f158e2e2e936c3faa48b035a6d
        e17beaac23b5f03b10b868d53d03521d
        8ba115059da777a60cbfd7b2c9c57472
        78a15b8f6e68a3ef7fd583ec9f398c8b
        d4735dab40cbd1e3c62a822e97489186
        c30a0b48c7c38ea32ceb056d3fa5a710
        e10ccc7a0ddb363b08c3d2777a3395e1
        0c0b6080f56309192ab5aacd4b45f55d
        a61fc77af39bd81a19218a79762c3386
        2df55785075f37d8c71dc8a42097ee43
        344739a0dd48d03025b0450cf1fb5e8c
        aeb893d9a96d1f15519bb3c4dcb40ee3
        16672ea16c012664f8a9f11255518deb
        -----END OpenVPN Static key V1-----
        </tls-auth>
      '';
      authUserPass = {
        inherit (secrets.vpn) username password;
      };
    };
  };

  xdg.portal.wlr.enable = true;

  services.flatpak.enable = true;

  virtualisation = {
    docker.enable = true;
    lxd.enable = true;
  };

  users.mutableUsers = false;

  users.defaultUserShell = pkgs.zsh;

  users.users.root.hashedPassword = secrets.users.root.hashedPassword;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.william = {
    uid = 1000;
    description = "William Hua";
    isNormalUser = true;
    hashedPassword = secrets.users.william.hashedPassword;
    extraGroups = [
      "docker"
      "sway"
      "video"
      "wheel"
    ];
  };

  home-manager.users.william = let mozilla = import (builtins.fetchGit {
    url = "https://github.com/mozilla/nixpkgs-mozilla.git";
    ref = "master";
  }); in { pkgs, ... }: {
    nixpkgs.overlays = [
      mozilla
      (self: super: {
        latest.rustChannels.stable.rust = super.latest.rustChannels.stable.rust.override {
          targets = [
            "wasm32-unknown-unknown"
          ];

          extensions = [
            "clippy-preview"
            "rust-src"
            "rustfmt-preview"
          ];
        };
      })
    ];

    programs.home-manager.enable = true;

    services.syncthing.enable = true;

    programs.neovim.enable = true;
    programs.neovim.viAlias = true;
    programs.neovim.vimAlias = true;
    programs.neovim.plugins = with pkgs.vimPlugins; [
      cmp-buffer
      cmp-nvim-lsp
      cmp-nvim-lsp-signature-help
      cmp-path
      cmp_luasnip
      fzf-vim
      gitgutter
      luasnip
      nvim-cmp
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
      rust-vim
      typescript-vim
      vimwiki
    ];

    programs.git.enable = true;
    programs.git.userName = "William Hua";
    programs.git.userEmail = "william@attente.ca";
    programs.git.extraConfig = {
      pull = {
        rebase = true;
      };

      push = {
        useForceIfIncludes = true;
      };

      merge = {
        autoStash = true;
        conflictStyle = "zdiff3";
        tool = "nvimdiff";
      };

      rebase = {
        autoSquash = true;
        autoStash = true;
      };

      url = {
        "ssh://git@github.com/0xsequence" = {
          insteadOf = "https://github.com/0xsequence";
        };
        "ssh://git@github.com/horizon-games" = {
          insteadOf = "https://github.com/horizon-games";
        };
      };
    };

    programs.git.delta.enable = true;
    programs.git.lfs.enable = true;

    programs.fzf.enable = true;
    programs.fzf.enableZshIntegration = true;
    programs.fzf.defaultCommand = "fd -L 2>/dev/null";
    programs.fzf.changeDirWidgetCommand = "fd -L -t d 2>/dev/null";
    programs.fzf.fileWidgetCommand = "fd -L -t f -t l 2>/dev/null";

    home.packages = with pkgs; [
      alacritty
      ansifilter
      bandwhich
      baobab
      bat
      binaryen
      bottom
      bubblewrap
      d-spy
      docker-compose
      du-dust
      evince
      exa
      fd
      fdupes
      file
      firefox
      gitg
      glib
      gnome.eog
      gnome.nautilus
      gnumake
      gnupg
      go
      (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.gke-gcloud-auth-plugin])
      gopls
      imagemagick
      inkscape
      inotify-tools
      jq
      keepassxc
      latest.rustChannels.stable.rust
      lazydocker
      ldns
      libreoffice
      lldb
      lm_sensors
      lsd
      man-pages
      mercurial
      nix-index
      nodePackages_latest.pnpm
      nodePackages_latest.typescript-language-server
      nodejs_latest
      openssl
      pavucontrol
      pkg-config
      plasma5Packages.kdeconnect-kde
      poppler_utils
      postgresql
      procs
      pulseaudio
      pulumi-bin
      python3
      rclone
      ripgrep
      sd
      shellcheck
      sqlite
      tealdeer
      tmate
      tree
      tree-sitter
      ungoogled-chromium
      unzip
      vlc
      vscodium
      wabt
      weechat
      wget
      wireshark
      xdg-utils
      (yarn.override {
        nodejs = nodejs_latest;
      })
      zip
    ];

    home.stateVersion = "18.09";
  };

  # users.extraUsers.guest = {
  #   isNormalUser = true;
  #   uid = 1000;
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "18.03"; # Did you read the comment?

}
