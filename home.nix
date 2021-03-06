let mozilla = import (builtins.fetchGit {
  url = "https://github.com/andersk/nixpkgs-mozilla.git";
  ref = "stdenv.lib";
  rev = "3499e085fb6ae1a846bcf425fa9c98a3b77480da";
}); in

{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    mozilla
    (self: super: {
      latest = {
        firefox-nightly-bin = super.latest.firefox-nightly-bin;

        rustChannels.nightly.rust = (super.rustChannelOf {
          channel = "nightly";
          date = "2021-05-20";
        }).rust.override {
          targets = [
            "wasm32-unknown-unknown"
          ];

          extensions = [
            "clippy-preview"
            "rust-src"
            "rustfmt-preview"
          ];
        };
      };
    })
  ];

  programs.home-manager.enable = true;

  services.syncthing.enable = true;

  programs.neovim.enable = true;
  programs.neovim.viAlias = true;
  programs.neovim.vimAlias = true;
  programs.neovim.plugins = with pkgs.vimPlugins; [
    coc-nvim
    fzf-vim
    gitgutter
    rust-vim
    typescript-vim
    vimwiki
  ];
  programs.neovim.extraConfig = ''
    set nu
    set et
    set si
    set sts=2
    set sw=2
    set ts=8

    syn on
    highlight spaces ctermbg=red guibg=red
    autocmd syntax * syn match spaces / \+\ze\t\|\s\+$/

    set list
    set lcs=tab:↹·

    set ut=100

    set sb
    set spr

    autocmd TermOpen * startinsert

    nmap <silent> [g <Plug>(coc-diagnostic-prev)
    nmap <silent> ]g <Plug>(coc-diagnostic-next)
    nmap <silent> gd <Plug>(coc-definition)
    nmap <silent> gy <Plug>(coc-type-definition)
    nmap <silent> gi <Plug>(coc-implementation)
    nmap <silent> gr <Plug>(coc-references)
  '';

  programs.git.enable = true;
  programs.git.userName = "William Hua";
  programs.git.userEmail = "william@attente.ca";
  programs.git.extraConfig = {
    pull = {
      rebase = true;
    };

    rebase = {
      autoSquash = true;
      autoStash = true;
    };

    url = {
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
    bat
    binaryen
    bottom
    bubblewrap
    dfeet
    docker-compose
    du-dust
    evince
    exa
    fd
    fdupes
    file
    firefox
    glib
    gnome3.eog
    gnome3.nautilus
    gnumake
    gnupg
    go
    imagemagick
    inkscape
    inotifyTools
    jq
    kdeconnect
    keepassxc
    latest.rustChannels.nightly.rust
    lazydocker
    ldns
    libreoffice
    lldb
    lm_sensors
    lsd
    manpages
    mercurial
    nix-index
    nodejs_latest
    openssl
    procs
    (pass.overrideAttrs (oldAttrs: {
      src = fetchGit {
        url = "https://git.zx2c4.com/password-store";
        rev = "b830119762416fa8706e479e9b01f2453d6f6ad6";
      };
      patches = [
        pass/set-correct-program-name-for-sleep.patch
      ];
    }))
    pkg-config
    poppler_utils
    postgresql
    python
    python3
    rclone
    ripgrep
    sage
    sd
    tealdeer
    tree
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

  imports = [
    "${fetchTarball "https://github.com/msteen/nixos-vsliveshare/tarball/a54bfc74c5e7ae056f61abdb970c6cd6e8fb5e53"}/modules/vsliveshare/home.nix"
  ];

  services.vsliveshare = {
    enable = false;
    extensionsDir = "$HOME/.vscode-oss/extensions";
    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/61cc1f0dc07c2f786e0acfd07444548486f4153b";
  };
}
