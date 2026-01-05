{
  flake-parts-lib,
  lib,
  self,
  ...
}:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types;
in
{
  options.perSystem = mkPerSystemOption {
    options.evalNix2GpuModule = mkOption {
      description = ''
        Function for evaluating a configured `nix2gpu` instance
      '';
      type = types.functionTo types.raw;
    };
  };

  config.perSystem =
    {
      pkgs,
      self',
      inputs',
      ...
    }:
    {
      evalNix2GpuModule =
        module:
        lib.evalModules {
          modules = [
            self.modules.nix2gpu.default
            module
          ];
          specialArgs = { inherit pkgs self' inputs'; };
          class = "nix2gpu";
        };
    };
}
