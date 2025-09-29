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
  options = {
    nix2vast.extraStartupScript = lib.mkOption {
      description = ''
        extra commands to run on container startup.
      '';
      type = types.str;
    };

    startupScript = flake-parts-lib.mkPerSystemOption {
      description = ''
        nix2vast container startup script.
      '';
      type = types.package;
      internal = true;
    };
  };

  config.startupScript =
    {
      pkgs,
      self',
      system,
      ...
    }:
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

}
