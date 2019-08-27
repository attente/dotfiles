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

      set ut=100
    '';

    packages.myVimPackage = with pkgs.vimPlugins; {
      start = [
        coc-nvim
        gitgutter
        rust-vim
        typescript-vim
        vimwiki
      ];
    };
  };

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
    kdeconnect
    latest.rustChannels.stable.rust
    ldns
    libreoffice
    lm_sensors
    manpages
    mercurial
    nix-index
    nixops
    nodejs
    (pass.overrideAttrs (oldAttrs: {
      src = fetchGit {
        url = "https://git.zx2c4.com/password-store";
        rev = "e93e03705fb5b81f3af85f04c07ad0ee2190b6aa";
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
