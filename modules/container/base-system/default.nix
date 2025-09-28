{ config, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      packages.baseSystem =
        pkgs.runCommand "base-system"
          {
            allowSubstitutes = false;
            preferLocalBuild = true;
          }
          ''
            exec ${config.packages.${system}.createBaseSystem}/bin/create-system.sh
          '';
    };
}
