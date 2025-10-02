{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.baseSystem = mkOption {
      description = ''
        nix2vast generated baseSystem.
      '';
      type = types.package;
      internal = true;
    };
  });

  config.perSystem =
    { pkgs, self', ... }:
    {
      baseSystem =
        pkgs.runCommand "base-system"
          {
            allowSubstitutes = false;
            preferLocalBuild = true;
          }
          ''
            exec ${self'.packages.createBaseSystem}/bin/create-system.sh
          '';
    };
}
