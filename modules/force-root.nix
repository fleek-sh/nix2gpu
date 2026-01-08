{ lib, ... }:
{
  flake.homeModules.force-root-user = {
    home.username = lib.mkForce "root";
    home.homeDirectory = lib.mkForce "/root";
  };
}
