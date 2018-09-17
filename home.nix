{ pkgs, ... }:

{
  programs.home-manager.enable = true;
  programs.home-manager.path = "/home/william/.home-manager";

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
    '';
  };

  programs.git.enable = true;
  programs.git.userName = "William Hua";
  programs.git.userEmail = "william@attente.ca";

  home.packages = with pkgs; [
    binutils-unwrapped
    firefox
    gcc
    gnumake
    gnupg
    nix-index
    pass
    python
    python3
    unzip
    yarn
  ];
}
