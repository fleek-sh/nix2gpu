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
  perContainer =
    { name, nix2vastConfig, ... }:
    {
      options = {
        "${name}-startupScript" = flake-parts-lib.mkPerSystemOption {
          description = ''
            nix2vast container ${name} startup script.
          '';
          type = types.package;
          internal = true;
        };
      };

      config."${name}-startupScript" =
        {
          pkgs,
          self',
          system,
          ...
        }:
        let
          scriptText =
            (builtins.readFile ./startup.sh)
            ++ nix2vastConfig.extraStartupScript
            ++ ''
              echo "[nix2vast] entering interactive terminal..."
              exec bash
            '';
        in
        pkgs.writeShellApplication {
          name = "${name}-startup.sh";
          text = scriptText;

          runtimeInputs = [
            self'.packages.corePkgs
            self'.packages.networkPkgs
            config.${system}.homeConfigurations.default.activationPackage
          ];
        };
    };
}
