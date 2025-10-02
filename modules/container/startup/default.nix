{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.perContainer = config.flake.lib.mkPerContainerOption (
      { container, ... }:
      {
        options."${container.name}-startupScript" = flake-parts-lib.mkPerSystemOption {
          description = ''
            nix2vast container ${container.name} startup script.
          '';
          type = types.package;
          internal = true;
        };
      }
    );
  });

  config.perSystem =
    {
      pkgs,
      self',
      system,
      ...
    }:
    {
      perContainer =
        { container, ... }:
        {
          "${container.name}-startupScript" =
            let
              scriptText =
                (builtins.readFile ./startup.sh)
                ++ container.options.extraStartupScript
                ++ ''
                  echo "[nix2vast] entering interactive terminal..."
                  exec bash
                '';
            in
            pkgs.writeShellApplication {
              name = "${container.name}-startup.sh";
              text = scriptText;

              runtimeInputs = [
                self'.packages.corePkgs
                self'.packages.networkPkgs
                config.${system}.homeConfigurations.default.activationPackage
              ];
            };
        };
    };
}
