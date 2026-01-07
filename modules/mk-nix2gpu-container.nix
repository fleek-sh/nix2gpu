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
    { config, inputs', pkgs, ... }:
    {
      mkNix2GpuContainer =
        name: module:
        let
          nimi = inputs'.nimi.packages.default;

          evaluatedConfig = (config.evalNix2GpuModule name module).config;

          settings = (lib.evalModules {
            modules = [
              { _module.check = false; imports = [ evaluatedConfig.nimiSettings ]; }
            ];
            specialArgs = { inherit pkgs; };
            class = "nimi";
          }).config;

          image = nimi.mkContainerImage {
            inherit (evaluatedConfig) services meta;
            inherit settings;
          };
        in
        image.overrideAttrs (old: {
          passthru = (old.passthru or { }) // evaluatedConfig.passthru;
        });
    };
}
