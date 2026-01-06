{ lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) types mkOption;
in
{
  options.perSystem = mkPerSystemOption {
    options.mkNix2GpuContainer = mkOption {
      description = ''
        Build a `nix2gpu` container
      '';
      type = types.functionTo types.raw;
    };
  };

  config.perSystem =
    { config, inputs', ... }:
    {
      mkNix2GpuContainer =
        name: module:
        let
          evaluatedConfig = (config.evalNix2GpuModule name module).config;
          image = inputs'.nimi.packages.default.mkContainerImage {
            inherit (evaluatedConfig) services meta;
            settings = evaluatedConfig.nimiSettings;
          };
        in
        image.overrideAttrs (old: {
          passthru = (old.passthru or { }) // evaluatedConfig.passthru;
        });
    };
}
