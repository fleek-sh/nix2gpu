{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types mkOption;

  executablePackage = types.package // {
    check = x: lib.isDerivation x && lib.hasAttr "mainProgram" x.meta;
  };
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.perContainer = config.flake.lib.mkPerContainerOption (_: {
      options.scripts = mkOption {
        description = ''
          nix2gpu's scripts to attach to containers after generation.
        '';
        type = types.attrsOf executablePackage;
        internal = true;
      };
    });
  });
}
