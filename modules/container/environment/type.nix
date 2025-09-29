{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types;
in
{
  options.environment = flake-parts-lib.mkPerSystemOption {
    description = ''
      nix2vast environment packages.
    '';
    type = types.attrsOf types.package;
    internal = true;
  };
}
