{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types mkOption;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.perContainer = config.flake.lib.mkPerContainerOption (
      { container, ... }:
      {
        options.baseSystem = mkOption {
          description = ''
            nix2vast generated baseSystem for ${container.name}.
          '';
          type = types.package;
          internal = true;
        };
      }
    );
  });

  config.perSystem =
    { pkgs, ... }:
    {
      perContainer =
        { config, ... }:
        {
          baseSystem =
            pkgs.runCommand "base-system"
              {
                allowSubstitutes = false;
                preferLocalBuild = true;
              }
              ''
                exec ${config.createBaseSystem}/bin/create-system.sh
              '';
        };
    };
}
