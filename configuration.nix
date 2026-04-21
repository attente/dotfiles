# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

let
  home-manager = inputs.home-manager;
  secrets = import ./secrets.nix;
in

{
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
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

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 65536;
  };

  networking.hostName = "oxygen"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_CA.UTF-8";
    LC_IDENTIFICATION = "en_CA.UTF-8";
    LC_MEASUREMENT = "en_CA.UTF-8";
    LC_MONETARY = "en_CA.UTF-8";
    LC_NAME = "en_CA.UTF-8";
    LC_NUMERIC = "en_CA.UTF-8";
    LC_PAPER = "en_CA.UTF-8";
    LC_TELEPHONE = "en_CA.UTF-8";
    LC_TIME = "en_CA.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      cantarell-fonts
      nerd-fonts.noto
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-monochrome-emoji
      roboto
    ];
  };

  users.mutableUsers = false;

  users.defaultUserShell = pkgs.zsh;

  users.users.root.hashedPassword = secrets.users.root.hashedPassword;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.william = {
    uid = 1000;
    isNormalUser = true;
    description = "William Hua";
    hashedPassword = secrets.users.william.hashedPassword;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJDbwYv/HQpTJJ/OoqLDCOIl/8/OB6PquYTQ1t8I8z4 william@helium"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILL5GUQhsPlfsxHbpWnJ4XrLuzD1zchWKzfBO7kIxn0P platinum"
    ];
    extraGroups = [
      "docker"
      "kvm"
      "libvirtd"
      "networkmanager"
      "render"
      "video"
      "wheel"
    ];
    packages = with pkgs; [];
  };

  home-manager.users.william = {
    programs.home-manager.enable = true;

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      withPython3 = false;
      withRuby = false;
      plugins = with pkgs.vimPlugins; [
        cmp-buffer
        cmp-nvim-lsp
        cmp-nvim-lsp-signature-help
        cmp-path
        cmp_luasnip
        fzf-vim
        luasnip
        nvim-cmp
        nvim-lspconfig
        nvim-treesitter-context
        nvim-treesitter-legacy.withAllGrammars
        plenary-nvim
        rust-vim
        telescope-nvim
        tokyonight-nvim
        typescript-vim
        vim-gitgutter
        vimwiki
      ];
      initLua = ''
        vim.o.expandtab = true
        vim.o.list = true
        vim.o.listchars = 'tab:•·'
        vim.o.mouse = '''
        vim.o.number = true
        vim.o.shiftwidth = 2 -- indent size
        vim.o.softtabstop = -1 -- tab size when typing, -1 = use shiftwidth
        vim.o.splitbelow = true
        vim.o.splitright = true
        vim.o.termguicolors = true
        vim.o.updatetime = 100

        vim.opt.clipboard:append("unnamedplus")

        vim.cmd 'colorscheme tokyonight'

        local cmp = require 'cmp'
        local cmp_nvim_lsp = require 'cmp_nvim_lsp'
        local luasnip = require 'luasnip'
        local nvim_treesitter = require 'nvim-treesitter.configs'
        local telescope = require 'telescope.builtin'
        local treesitter_context = require 'treesitter-context'

        -- nvim-cmp is a completion plugin
        -- cmp-nvim-lsp is an nvim-cmp source for neovim's native lsp client
        -- cmp_luasnip is an nvim-cmp source for luasnip snippets
        -- luasnip is a snippet plugin
        -- nvim-lspconfig is a repo of predefined lsp configs
        -- nvim-treesitter is an interface to the tree-sitter parser
        -- telescope is a fuzzy finder over lists
        -- treesitter-context is a context plugin

        cmp.setup {
          mapping = cmp.mapping.preset.insert {
            ['<Tab>'] = cmp.mapping.confirm({ select = true }),
          },
          sources = cmp.config.sources({
            { name = 'nvim_lsp_signature_help' },
          }, {
            { name = 'nvim_lsp' },
          }, {
            { name = 'luasnip' },
          }, {
            { name = 'buffer' },
          }, {
            { name = 'path' },
          }),
          snippet = {
            expand = function (args)
              luasnip.lsp_expand(args.body)
            end,
          },
        }

        local capabilities = cmp_nvim_lsp.default_capabilities()

        local options = { noremap = true, silent = true }
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, options)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next, options)
        vim.keymap.set('n', '<space>fd', telescope.diagnostics, options)
        vim.keymap.set('n', '<space>ff', telescope.find_files, options)
        vim.keymap.set('n', '<space>fg', telescope.live_grep, options)

        local on_attach = function (client, buffer)
          local options = { noremap = true, silent = true, buffer = buffer }
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, options)
          vim.keymap.set('n', 'gd', telescope.lsp_definitions, options)
          vim.keymap.set('n', 'gr', telescope.lsp_references, options)
          vim.keymap.set('n', '<space>D', telescope.lsp_type_definitions, options)
          vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, options)
          vim.keymap.set('n', '<space>f', function () vim.lsp.buf.format { async = true } end, options)
        end

        vim.lsp.config('*', {
          capabilities = capabilities,
          on_attach = on_attach,
        })

        vim.lsp.enable('gopls')
        vim.lsp.enable('rust_analyzer')
        vim.lsp.enable('ts_ls')

        nvim_treesitter.setup {
          highlight = {
            enable = true,
          },
          indent = {
            enable = true,
          },
        }

        treesitter_context.setup {
          multiwindow = true,
          mode = 'topline',
          trim_scope = 'inner',
        }
      '';
    };

    programs.git = {
      enable = true;

      settings = {
        user = {
          name = "William Hua";
          email = "william@attente.ca";
        };

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

        log = {
          abbrevCommit = false;
        };

        advice = {
          skippedCherryPicks = false;
        };

        url = {
          "ssh://git@github.com/0xPolygon" = {
            insteadOf = "https://github.com/0xPolygon";
          };
          "ssh://git@github.com/0xsequence" = {
            insteadOf = "https://github.com/0xsequence";
          };
          "ssh://git@github.com/horizon-games" = {
            insteadOf = "https://github.com/horizon-games";
          };
        };
      };

      lfs.enable = true;
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd -L 2>/dev/null";
      changeDirWidgetCommand = "fd -L -t d 2>/dev/null";
      fileWidgetCommand = "fd -L -t f -t l 2>/dev/null";
    };

    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;
    };

    home.packages = with pkgs; [
      alacritty
      ansifilter
      awww
      bandwhich
      baobab
      bat
      binaryen
      bottom
      brightnessctl
      bubblewrap
      bun
      codex
      d-spy
      devenv
      docker-compose
      dunst
      dust
      eog
      evince
      eww
      fd
      fdupes
      ffmpeg
      file
      firefox
      gitg
      glib
      gnumake
      gnupg
      go
      (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.gke-gcloud-auth-plugin])
      gopls
      grim
      hypridle
      imagemagick
      inkscape
      inotify-tools
      jq
      kdePackages.kdeconnect-kde
      keepassxc
      lazydocker
      ldns
      libreoffice
      lldb
      lm_sensors
      lsd
      man-pages
      mercurial
      nautilus
      nix-index
      nodejs_20
      openssl
      pavucontrol
      pkg-config
      pnpm
      poppler-utils
      postgresql
      procs
      pulseaudio
      python3
      qt5.qtwayland
      rclone
      ripgrep
      sd
      shellcheck
      slurp
      sqlite
      tealdeer
      tmate
      tree
      tree-sitter
      typescript-language-server
      ungoogled-chromium
      unzip
      vlc
      vscodium
      wabt
      walker
      waypipe
      weechat
      wf-recorder
      wget
      (whisper-cpp.override { rocmSupport = true; })
      wireshark
      wl-clipboard
      xdg-utils
      zip
    ];

    home.pointerCursor = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 64;
      gtk.enable = true;
    };

    xdg.desktopEntries = {
      youtube-music = {
        name = "YouTube Music";
        exec = "chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --user-data-dir=/home/william/.config/youtube-music --app=https://music.youtube.com";
      };
    };

    home.stateVersion = "25.11";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
    neovim
  ];

  environment.shellAliases = {
    nix-shell = "nix-shell --command zsh";
    vi = "nvim";
  };

  environment.shellInit = ''
    export EDITOR=nvim
    export VISUAL=nvim
    export COREPACK_ENABLE_AUTO_PIN=0
    export CODEX_HOME=~/.config/codex
  '';

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

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

  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;

  programs.ssh.startAgent = true;

  programs.virt-manager.enable = true;

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

  services.logind.settings.Login = {
    RuntimeDirectoryInodesMax = "1000000000";
    RuntimeDirectorySize = "25%";
  };

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

  services.tailscale.enable = true;
  services.resolved.enable = true;
  networking.networkmanager.dns = "systemd-resolved";

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  services.gvfs.enable = true;

  services.pcscd.enable = true;

  services.flatpak.enable = true;

  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
  };

  services.elephant.enable = true;

  services.ollama = with pkgs; {
    enable = true;
    package = ollama-rocm;
    rocmOverrideGfx = "10.3.0";
  };

  services.hermes-agent = {
    enable = true;
    environmentFiles = [ "/var/lib/hermes/env" ];
    addToSystemPackages = true;
    container = {
      enable = true;
      hostUsers = [ "william" ];
    };
  };

  services.trezord.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
