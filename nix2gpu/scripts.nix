{ config, lib, ... }:
let
  inherit (lib) types mkOption;

  executablePackageType = types.package // {
    check = x: lib.isDerivation x && lib.hasAttr "mainProgram" x.meta;
  };
in
{
  options.scripts = mkOption {
    description = ''
      nix2gpu's scripts to attach to containers after generation.
    '';
    type = types.lazyAttrsOf executablePackageType;
    internal = true;
  };

  config.passthru = {
    tests = lib.mapAttrs' (
      name: value: lib.nameValuePair ("is-valid-script-" + name) value
    ) config.scripts;
  }
  // config.scripts;
}
