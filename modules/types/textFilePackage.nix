{
  lib,
  ...
}:
let
  inherit (lib) types;
in
{
  flake.modules.types.textFilePackage = types.package // {
    check = x: lib.isDerivation x && lib.hasAttr "text" x;
  };
}
