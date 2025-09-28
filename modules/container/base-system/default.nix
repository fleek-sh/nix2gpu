{ config, ... }:
{
  flake.modules.baseSystem =
    { pkgs, system, ... }:
    pkgs.runCommand "base-system"
      {
        allowSubstitutes = false;
        preferLocalBuild = true;
      }
      ''
        exec ${config.packages.${system}.createBaseSystem}/bin/create-system.sh
      '';
}
