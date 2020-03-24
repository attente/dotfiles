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

  programs.termite.enable = true;
  programs.termite.scrollbackLines = -1;

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
  '';

  programs.git.enable = true;
  programs.git.userName = "William Hua";
  programs.git.userEmail = "william@attente.ca";
  programs.git.extraConfig = {
    url = {
      "ssh://git@github.com/horizon-games" = {
        insteadOf = "https://github.com/horizon-games";
      };
    };
  };

  programs.git.lfs.enable = true;

  home.packages = with pkgs; [
    binaryen
    bubblewrap
    chromium
    d-spy
    docker-compose
    evince
    fdupes
    file
    firefox
    glib
    gnome3.eog
    gnome3.nautilus
    gnumake
    gnupg
    go
    gotop
    htop
    imagemagick
    inkscape
    inotifyTools
    jq
    kdeconnect
    latest.rustChannels.stable.rust
    ldns
    libreoffice
    lm_sensors
    manpages
    mercurial
    nix-index
    nixops
    nodejs-12_x
    (pass.overrideAttrs (oldAttrs: {
      src = fetchGit {
        url = "https://git.zx2c4.com/password-store";
        rev = "b830119762416fa8706e479e9b01f2453d6f6ad6";
      };
      patches = [
        pass/set-correct-program-name-for-sleep.patch
      ];
    }))
    poppler_utils
    python
    python3
    tree
    unzip
    wabt
    weechat
    wget
    wireshark
    zip
  ];
}
