{ pkgs, ... }:

{
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
      ];
    };
  };

  programs.git.enable = true;
  programs.git.userName = "William Hua";
  programs.git.userEmail = "william@attente.ca";

  home.packages = with pkgs; [
    binutils-unwrapped
    bubblewrap
    chromium
    evince
    fdupes
    file
    firefox
    gcc
    glib
    gnome3.eog
    gnome3.nautilus
    gnumake
    gnupg
    go
    imagemagick
    ldns
    lm_sensors
    manpages
    mercurial
    nix-index
    nixops
    pass
    python
    python3
    rustup
    tree
    unzip
    wabt
    weechat
    wget
  ];
}
