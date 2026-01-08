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
          nimi = inputs'.nimi.packages.default;

          nix2gpuCfg = (config.evalNix2GpuModule name module).config;

          image = nimi.mkContainerImage {
            inherit (nix2gpuCfg) services meta;
            imports = [
              # TODO[baileylu] Find a way to do this transformation less manually
              (lib.mkAliasOptionModule [ "container" ] [ "settings" "container" ])
              (lib.mkAliasOptionModule [ "startup" ] [ "settings" "startup" ])
              (lib.mkAliasOptionModule [ "logging" ] [ "settings" "logging" ])
              (lib.mkAliasOptionModule [ "restart" ] [ "settings" "restart" ])
              nix2gpuCfg.nimiSettings
            ];
          };
        in
        image.overrideAttrs (old: {
          passthru = (old.passthru or { }) // nix2gpuCfg.passthru;
        });
    };
}
