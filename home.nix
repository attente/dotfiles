let mozilla = import (builtins.fetchGit {
  url = "https://github.com/mozilla/nixpkgs-mozilla.git";
  ref = "master";
  rev = "507efc7f62427ded829b770a06dd0e30db0a24fe";
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
          "rustfmt-preview"
        ];
      };
    })
  ];

  programs.home-manager.enable = true;

  programs.termite.enable = true;

  programs.neovim.enable = true;
  programs.neovim.viAlias = true;
  programs.neovim.vimAlias = true;
  programs.neovim.configure = {
    customRC = ''
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
        typescript-vim
        vimwiki
      ];
    };
  };

  programs.git.enable = true;
  programs.git.userName = "William Hua";
  programs.git.userEmail = "william@attente.ca";

  home.packages = with pkgs; [
    bubblewrap
    chromium
    d-spy
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
    imagemagick
    latest.rustChannels.stable.rust
    ldns
    libreoffice
    lm_sensors
    manpages
    mercurial
    nix-index
    nixops
    pass
    python
    python3
    tree
    unzip
    wabt
    weechat
    wget
  ];
}
