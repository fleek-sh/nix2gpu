{ config, lib, ... }:
let
  inherit (lib) types;
in
{
  options.nix2vast.extraStartupScript = lib.mkOption {
    description = ''
      extra commands to run on container startup.
    '';
    type = types.str;
  };

  config.perSystem =
    {
      pkgs,
      self',
      system,
      ...
    }:
    {
      packages.startupScript =
        let
          scriptText =
            (builtins.readFile ./startup.sh)
            ++ config.nix2vast.${system}.extraStartupScript
            ++ ''
              echo "[nix2vast] entering interactive terminal..."
              exec bash
            '';
        in
        pkgs.writeShellApplication {
          name = "startup.sh";
          text = scriptText;

          runtimeInputs = [
            self'.packages.corePkgs
            self'.packages.networkPkgs
            config.${system}.homeConfigurations.default.activationPackage
          ];
        };
    };

}
