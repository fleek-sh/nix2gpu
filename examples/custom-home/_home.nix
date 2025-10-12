{ pkgs, ... }:
{
  home.stateVersion = "25.11";
  home.username = "root";
  home.homeDirectory = "/root";

  environment.systemPackages = with pkgs; [ cowsay ];
}
