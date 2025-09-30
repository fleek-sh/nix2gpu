{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.environment = mkOption {
      description = ''
        nix2vast environment packages.
      '';
      type = types.attrsOf types.package;
      internal = true;
      default = { };
    };
  });
}
