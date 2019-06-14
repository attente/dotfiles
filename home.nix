let mozilla = import (builtins.fetchGit {
  url = "https://github.com/mozilla/nixpkgs-mozilla.git";
  ref = "master";
  rev = "200cf0640fd8fdff0e1a342db98c9e31e6f13cd7";
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
  programs.neovim.configure = {
    customRC = ''
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
    '';

    packages.myVimPackage = with pkgs.vimPlugins; {
      start = [
        rust-vim
        typescript-vim
        vimwiki
      ];
    };
  };

  programs.git.enable = true;
  programs.git.userName = "William Hua";
  programs.git.userEmail = "william@attente.ca";

  home.packages = with pkgs; [
    binaryen
    bubblewrap
    chromium
    d-spy
    evince
    fdupes
    file
    firefox
    git-lfs
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
    latest.rustChannels.stable.rust
    ldns
    libreoffice
    lm_sensors
    manpages
    mercurial
    nix-index
    nixops
    nodejs-12_x
    pass
    poppler_utils
    python
    python3
    sage
    tree
    unzip
    wabt
    weechat
    wget
    wireshark
    wl-clipboard
    zip
  ];
}
