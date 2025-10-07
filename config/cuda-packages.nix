{ config, lib, ... }:
let
  inherit (lib) mkOption;
  inherit (config) rootConfig pkgs;
in
{
  options.cudaPackages = mkOption {
    description = ''
      the cuda packages source to use.

      this is useful for selecting a specific version
      on which your container relies.
    '';
    type = rootConfig.types.cudaPackageSet;
    default = pkgs.cudaPackages_12_8;
  };
}
