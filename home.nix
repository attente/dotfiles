let mozilla = import (builtins.fetchGit {
  url = "https://github.com/mozilla/nixpkgs-mozilla.git";
  ref = "master";
}); in

{ pkgs, ... }:

{
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

  programs.neovim.enable = true;
  programs.neovim.viAlias = true;
  programs.neovim.vimAlias = true;
  programs.neovim.plugins = with pkgs.vimPlugins; [
    coc-nvim
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

  home.packages = with pkgs; [
    alacritty
    bandwhich
    bat
    binaryen
    bubblewrap
    chromium
    d-spy
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
    latest.rustChannels.stable.rust
    ldns
    libreoffice
    lldb
    lm_sensors
    lsd
    manpages
    mercurial
    nix-index
    nixops
    nodejs-12_x
    openssl
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
    procs
    python
    python3
    ripgrep
    sd
    tealdeer
    tree
    unzip
    vscodium
    wabt
    weechat
    wget
    wireshark
    ytop
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
