# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, pkgs-stable, inputs, ... }:

let
  home-manager = inputs.home-manager;
  secrets = import ./secrets.nix;
in

{
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };

  nixpkgs.config.allowUnfree = true;

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
    keyMap = "us";
    font = "cozette12x26";
    packages = [ pkgs.cozette ];
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
      pkgs-stable.cantarell-fonts
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
    shell = pkgs.zsh;
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
        nvim-treesitter.withAllGrammars
        plenary-nvim
        rust-vim
        telescope-nvim
        tokyonight-nvim
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
        local nvim_treesitter = require 'nvim-treesitter'
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

        nvim_treesitter.setup {}

        local treesitter_group = vim.api.nvim_create_augroup('treesitter', { clear = true })

        vim.api.nvim_create_autocmd('FileType', {
          group = treesitter_group,
          pattern = '*',
          callback = function(args)
            local ok = pcall(vim.treesitter.start, args.buf)
            if ok then
              vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
          end,
        })

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

        gpg = {
          ssh = {
            defaultKeyCommand = "ssh-add -L";
          };
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

      signing.format = "ssh";
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };

    programs.mercurial = {
      enable = true;
      userName = "William Hua";
      userEmail = "william@attente.ca";
      extraConfig.extensions = {
        purge = "";
        share = "";
      };
    };

    programs.npm = {
      enable = true;
      package = pkgs.nodejs_latest;
      settings.prefix = "/home/william/.npm";
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd -L 2>/dev/null";
      changeDirWidgetCommand = "fd -L -t d 2>/dev/null";
      fileWidgetCommand = "fd -L -t f -t l 2>/dev/null";
    };

    programs.tmux = {
      enable = true;
      prefix = "C-a";
      keyMode = "vi";
      baseIndex = 1;
      mouse = false;
      extraConfig = ''
        set-option -ga terminal-overrides ",xterm-256color:Tc"
        set -as terminal-features 'xterm*:extkeys'
      '';
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
        extraConfig = ''
          DISABLE_MAGIC_FUNCTIONS=true
        '';
      };
      initContent = ''
        if [ -n "''${commands[fzf]}" ]; then
          bindkey "^I" $fzf_default_completion
        fi

        if [ -n "''${commands[rg]}" ] && [ -n "''${commands[fzf]}" ]; then
          function __rg_fzf_edit_widget() {
            emulate -L zsh
            setopt localoptions pipefail no_aliases

            local selection file line editor rg_cmd
            rg_cmd="rg --vimgrep --color=always --smart-case --hidden --glob '!.git/*'"
            selection=$(
              fzf --ansi --phony --query "" --prompt "rg> " \
                --bind "start:reload:''${rg_cmd} -- {q} || true" \
                --bind "change:reload:''${rg_cmd} -- {q} || true"
            ) || return

            file="''${selection%%:*}"
            line="''${selection#*:}"
            line="''${line%%:*}"
            editor="''${EDITOR:-nvim}"
            BUFFER="''${editor} +''${line} ''${(q)file}"
            CURSOR=''${#BUFFER}
          }

          zle -N __rg_fzf_edit_widget
          bindkey "^F" __rg_fzf_edit_widget
        fi
      '';
    };

    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;
      settings = {
        model = "deepseek/deepseek-v4-flash";
        autoupdate = false;
      };
    };

    programs.alacritty = {
      enable = true;
      settings = builtins.fromTOML (builtins.readFile ./alacritty/alacritty.toml);
    };

    programs.eww = {
      enable = true;
      yuckConfig = builtins.readFile ./eww/eww.yuck;
      scssConfig = builtins.readFile ./eww/eww.scss;
      systemd = {
        enable = true;
        target = "hyprland-session.target";
      };
    };

    programs.hyprlock = {
      enable = true;
      package = null;
      settings = {
        general.ignore_empty_input = true;

        label = [
          {
            text = "cmd[update:1000] date +'%A, %B %e, %Y' | sd '  ' ' '";
            text_align = "center";
            font_size = 32;
            font_family = "TeX Gyre Pagella";
            position = "0, 400";
            halign = "center";
            valign = "center";
            shadow_passes = 3;
            shadow_size = 10;
          }
          {
            text = "cmd[update:1000] date +'%l:%M:%S %P'";
            text_align = "center";
            font_size = 96;
            font_family = "TeX Gyre Pagella";
            position = "0, 200";
            halign = "center";
            valign = "center";
            shadow_passes = 3;
            shadow_size = 10;
          }
          {
            text = "$ATTEMPTS";
            text_align = "center";
            font_size = 16;
            font_family = "TeX Gyre Pagella";
            position = "-100, 100";
            halign = "right";
            valign = "bottom";
            shadow_passes = 3;
            shadow_size = 10;
          }
        ];

        "input-field" = [
          {
            monitor = "";
            fade_on_empty = false;
            placeholder_text = "🔒";
            fail_text = "❌";
            outline_thickness = 8;
            capslock_color = "rgb(255, 0, 0)";
            position = "0, -100";
            shadow_passes = 5;
            shadow_size = 1;
            shadow_color = "rgb(128, 128, 128)";
          }
        ];

        background = [
          {
            path = "screenshot";
            blur_passes = 4;
            blur_size = 4;
          }
        ];
      };
    };

    programs.wofi = {
      enable = true;
      settings = {
        allow_images = true;
        allow_markup = true;
        insensitive = true;
        parse_search = true;
        prompt = "";
        term = "alacritty";
      };
      style = ./wofi/style.css;
    };

    services.dunst = {
      enable = true;
      iconTheme = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
        size = "64x64";
      };
      settings = {
        global = {
          monitor = 0;
          follow = "keyboard";
          width = 400;
          height = 200;
          origin = "top-center";
          offset = "0x32";
          scale = 0;
          notification_limit = 4;
          progress_bar = true;
          progress_bar_height = 10;
          progress_bar_frame_width = 1;
          progress_bar_min_width = 150;
          progress_bar_max_width = 300;
          progress_bar_corner_radius = 0;
          icon_corner_radius = 32;
          indicate_hidden = true;
          transparency = 0;
          separator_height = 2;
          padding = 8;
          horizontal_padding = 8;
          text_icon_padding = 0;
          frame_width = 0;
          frame_color = "#aaaaaa";
          gap_size = 8;
          separator_color = "frame";
          sort = true;
          font = "Sans 10";
          line_height = 0;
          markup = "full";
          format = "<b>%s</b>\\n%b";
          alignment = "left";
          vertical_alignment = "center";
          show_age_threshold = 60;
          ellipsize = "middle";
          ignore_newline = false;
          stack_duplicates = true;
          hide_duplicate_count = false;
          show_indicators = true;
          enable_recursive_icon_lookup = true;
          icon_theme = "Adwaita";
          icon_position = "left";
          min_icon_size = 64;
          max_icon_size = 64;
          sticky_history = true;
          history_length = 20;
          dmenu = "${pkgs.wofi}/bin/wofi --dmenu --prompt dunst:";
          browser = "${pkgs.xdg-utils}/bin/xdg-open";
          always_run_script = true;
          title = "Dunst";
          class = "Dunst";
          corner_radius = 8;
          ignore_dbusclose = false;
          force_xwayland = false;
          force_xinerama = false;
          mouse_left_click = "do_action, close_current";
          mouse_middle_click = "none";
          mouse_right_click = "close_current";
        };

        experimental.per_monitor_dpi = false;

        urgency_low = {
          background = "#222222e0";
          foreground = "#888888e0";
          timeout = 10;
        };

        urgency_normal = {
          background = "#285577e0";
          foreground = "#ffffffe0";
          timeout = 10;
        };

        urgency_critical = {
          background = "#900000e0";
          foreground = "#ffffff";
          frame_color = "#ff0000e0";
          timeout = 0;
        };
      };
    };

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "hyprlock --grace 5";
          before_sleep_cmd = "hyprlock --immediate --no-fade-in";
          ignore_dbus_inhibit = false;
          ignore_systemd_inhibit = false;
        };

        listener = [
          {
            timeout = 300;
            on-timeout = "hyprlock --grace 5";
          }
          {
            timeout = 600;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
          }
        ];
      };
    };

    services.walker = {
      enable = true;
      systemd.enable = true;
      settings = builtins.fromTOML (builtins.readFile ./walker/config.toml);
    };

    systemd.user.services.eww-status = {
      Unit = {
        Description = "Open Eww status windows";
        Requires = [ "eww.service" ];
        After = [ "eww.service" ];
        PartOf = [ "hyprland-session.target" ];
      };

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "eww-open-status" ''
          set -eu

          open_window() {
            local window="$1"

            for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
              if ${pkgs.eww}/bin/eww open "$window" >/dev/null 2>&1; then
                return 0
              fi
              ${pkgs.coreutils}/bin/sleep 0.25
            done

            ${pkgs.eww}/bin/eww open "$window"
          }

          open_window status-0
          open_window status-1
        '';
      };

      Install.WantedBy = [ "hyprland-session.target" ];
    };

    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      configType = "hyprlang";
      settings = {
        monitor = ",preferred,auto,2";
        "$mainMod" = "SUPER";

        exec-once = [
          "awww-daemon && awww img ~/.william/wallpapers/default.jpg"
          "elephant"
          "fcitx5"
        ];

        env = "XCURSOR_SIZE,24";

        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "";
          kb_rules = "";
          follow_mouse = 1;
          touchpad.natural_scroll = true;
          sensitivity = 0;
        };

        general = {
          gaps_in = 4;
          gaps_out = 8;
          border_size = 1;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
          layout = "dwindle";
        };

        decoration = {
          rounding = 4;
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
          };
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };
        };

        animations = {
          enabled = true;
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        dwindle = {
          force_split = 2;
          preserve_split = true;
        };

        master.new_status = "master";
        binds.movefocus_cycles_fullscreen = false;

        device = {
          name = "epic-mouse-v1";
          sensitivity = -0.5;
        };

        workspace = "name:special, gapsout:40, gapsin:20";

        bind = [
          "$mainMod, Q, exec, alacritty"
          "$mainMod, C, killactive,"
          "$mainMod, M, exit,"
          "$mainMod, E, exec, waypipe --no-gpu ssh phosphorus 'chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime'"
          "$mainMod, V, togglefloating,"
          "$mainMod, R, exec, walker"
          "$mainMod, P, pseudo,"
          "$mainMod, S, layoutmsg, togglesplit"
          "$mainMod, F, fullscreen, 0"
          "$mainMod, escape, exec, loginctl lock-session"
          "$mainMod SHIFT, escape, exec, loginctl lock-session && sleep 0.1 && systemctl suspend"
          "CTRL ALT, delete, exec, reboot"
          ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle && pactl set-sink-volume @DEFAULT_SINK@ 30%"
          ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -10%"
          ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +10%"
          ", XF86AudioMicMute, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle && pactl set-source-volume @DEFAULT_SOURCE@ 60%"
          ", XF86MonBrightnessDown, exec, brightnessctl set 25%-"
          ", XF86MonBrightnessUp, exec, brightnessctl set +25%"
          '', print, exec, grim -g "`hyprctl activewindow -j | jq -r '"\(.at[0]-4),\(.at[1]-4) \(.size[0]+8)x\(.size[1]+8)"'`" "/home/william/screenshots/`date --rfc-3339=seconds`.png"''
          ''CTRL, print, exec, grim -g "`slurp`" "/home/william/screenshots/`date --rfc-3339=seconds`.png"''
          "$mainMod, W, exec, chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime"
          "$mainMod, left, movefocus, l"
          "$mainMod, right, movefocus, r"
          "$mainMod, up, movefocus, u"
          "$mainMod, down, movefocus, d"
          "$mainMod SHIFT, left, movewindow, l"
          "$mainMod SHIFT, right, movewindow, r"
          "$mainMod SHIFT, up, movewindow, u"
          "$mainMod SHIFT, down, movewindow, d"
          "$mainMod, H, movefocus, l"
          "$mainMod, L, movefocus, r"
          "$mainMod, K, movefocus, u"
          "$mainMod, J, movefocus, d"
          "$mainMod SHIFT, H, movewindow, l"
          "$mainMod SHIFT, L, movewindow, r"
          "$mainMod SHIFT, K, movewindow, u"
          "$mainMod SHIFT, J, movewindow, d"
          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          "$mainMod, 0, workspace, 10"
          "$mainMod, minus, togglespecialworkspace"
          "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
          "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
          "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
          "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
          "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
          "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
          "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
          "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
          "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
          "$mainMod SHIFT, 0, movetoworkspacesilent, 10"
          "$mainMod SHIFT, minus, movetoworkspacesilent, special"
          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"
        ];

        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];
      };
    };

    gtk = {
      enable = true;
      colorScheme = "dark";
    };

    xdg.configFile = {
      "eww/scripts/package.json".source = ./eww/scripts/package.json;
      "eww/scripts/bun.lockb".source = ./eww/scripts/bun.lockb;
      "eww/scripts/volume.sh".source = ./eww/scripts/volume.sh;
      "eww/scripts/workspaces.ts".source = ./eww/scripts/workspaces.ts;
      "walker/themes/default.css".source = ./walker/themes/default.css;
      "walker/themes/default.toml".source = ./walker/themes/default.toml;
      "walker/themes/default_window.toml".source = ./walker/themes/default_window.toml;
    };

    home.sessionPath = [
      "/home/william/.william/etc/bin"
      "/home/william/.cargo/bin"
      "/home/william/go/bin"
      "/home/william/.npm/bin"
    ];

    home.sessionVariables = {
      GOPATH = "/home/william/go";
    };

    home.packages = with pkgs; [
      ansifilter
      awww
      bandwhich
      baobab
      bat
      binaryen
      biome
      bottom
      brightnessctl
      bubblewrap
      bun
      claude-code
      codex
      d-spy
      devenv
      docker-compose
      dust
      eog
      evince
      fd
      fdupes
      ffmpeg
      file
      firefox
      gcc
      gh
      gitg
      glib
      gnumake
      gnupg
      go
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
      mosh
      nautilus
      nix-index
      openssl
      pavucontrol
      pkg-config
      plex-desktop
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
      waypipe
      weechat
      wf-recorder
      wget
      (whisper-cpp.override { rocmSupport = true; })
      wireshark
      wl-clipboard
      xdg-utils
      yq-go
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

  programs.zsh.enable = true;

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
    containers = {
      enable = true;
      containersConf.settings.containers.default_network = "bridge";
    };

    docker.enable = true;

    podman = {
      enable = true;
      dockerCompat = false;
    };

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

  services.trezord.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
