{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types;
in
{
  options.baseSystem = flake-parts-lib.mkPerSystemOption {
    description = ''
      nix2vast generated baseSystem.
    '';
    type = types.package;
    internal = true;
  };

  config.baseSystem =
    { pkgs, self', ... }:
    pkgs.runCommand "base-system"
      {
        allowSubstitutes = false;
        preferLocalBuild = true;
      }
      ''
        exec ${self'.packages.createBaseSystem}/bin/create-system.sh
      '';
}
