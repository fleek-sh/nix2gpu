{ pkgs, ... }:
{
  home.stateVersion = "25.11";
  home.username = "root";
  home.homeDirectory = "/root";
  home.packages = [ pkgs.cowsay ];
}
