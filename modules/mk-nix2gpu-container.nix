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
      type = types.functionTo types.package;
    };
  };

  config.perSystem =
    { config, inputs', ... }:
    {
      mkNix2GpuContainer =
        module:
        let
          evaluatedConfig = (config.evalNix2GpuModule module).config;
        in
        inputs'.nimi.packages.default.mkContainerImage {
          inherit (evaluatedConfig) services;
          settings = evaluatedConfig.nimiSettings;
        };
    };
}
