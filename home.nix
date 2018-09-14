{ pkgs, ... }:

{
  programs.home-manager.enable = true;
  programs.home-manager.path = "/home/william/.home-manager";

  programs.termite.enable = true;

  programs.git.enable = true;
  programs.git.userName = "William Hua";
  programs.git.userEmail = "william@attente.ca";

  home.packages = with pkgs; [
    gnupg
    nix-index
    pass
  ];
}
