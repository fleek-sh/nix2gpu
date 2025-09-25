{
  lib,
  ...
}:
let
  inherit (lib) types;
in
{
  flake.modules.types.cudaPackageSet = types.package // {
    check = x: lib.isDerivation x && lib.hasAttr "cudatoolkit" x;
  };
}
