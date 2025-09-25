{ config, ... }:
{
  options.nix2vast.perSystem =
    { pkgs, ... }:
    {
      cudaPackages = pkgs.mkOption {
        description = ''
          the cuda packages source to use.

          this is useful for selecting a specific version
          on which your container relies.
        '';
        type = config.types.cudaPackageSet;
        default = pkgs.cudaPackages_12_8;
      };
    };
}
