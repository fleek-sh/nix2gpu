{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types;

  executablePackage = types.package // {
    check = x: lib.isDerivation x && lib.hasAttr "mainProgram" x.meta;
  };
in
{
  options.scripts = flake-parts-lib.mkPerSystemOption {
    description = ''
      nix2vast's scripts to attach to containers after generation.
    '';
    type = types.attrsOf executablePackage;
    internal = true;
  };
}
