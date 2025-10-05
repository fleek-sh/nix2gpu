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
        options.startupScript = mkOption {
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
      config,
      ...
    }:
    let
      outerConfig = config;
    in
    {
      perContainer =
        { container, config, ... }:
        {
          startupScript =
            let
              scriptText = ''
                ${builtins.readFile ./startup.sh}
                ${outerConfig.nix2vast.${container.name}.extraStartupScript}
                echo "[nix2vast] entering interactive terminal..."
                exec bash
              '';
            in
            pkgs.writeShellApplication {
              name = "${container.name}-startup.sh";
              text = scriptText;

              runtimeInputs = with config; [
                environment.corePkgs
                environment.networkPkgs
                outerConfig.homeConfigurations.default.activationPackage
              ];
            };
        };
    };
}
