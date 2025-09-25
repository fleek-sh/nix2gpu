{ config, lib, ... }:
let
  inherit (lib) types;
in
{
  options.nix2vast.perSystem =
    { pkgs, ... }:
    {
      extraStartupScript = pkgs.mkOption {
        description = ''
          extra commands to run on container startup.
        '';
        type = types.str;
      };
    };

  flake.modules.nix2vast.perSystem =
    { pkgs, system, ... }:
    let
      scriptText =
        (builtins.readFile ./startup.sh)
        ++ config.nix2vast.${system}.extraStartupScript
        ++ ''
          echo "[nix2vast] entering interactive terminal..."
          exec bash
        '';
    in
    {
      startupScript = pkgs.writeShellApplication {
        name = "startup.sh";
        text = scriptText;

        runtimeInputs =
          config.${system}.corePkgs
          ++ config.${system}.networkPkgs
          ++ [
            config.${system}.homeConfigurations.default.activationPackage
          ];
      };
    };
}
