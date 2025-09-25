{ flake-parts-lib, ... }:
{
  options.nix2vast.cudaPackages = flake-parts-lib.mkPerSystemOption (
    { pkgs, config, ... }:
    {
      description = ''
        the cuda packages source to use.

        this is useful for selecting a specific version
        on which your container relies.
      '';
      type = config.types.cudaPackageSet;
      default = pkgs.cudaPackages_12_8;
    }
  );
}
