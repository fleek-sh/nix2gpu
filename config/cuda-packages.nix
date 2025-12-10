{ config, lib, ... }:
let
  inherit (lib) mkOption literalExpression;
  inherit (config) rootConfig pkgs;
in
{
  options.cudaPackages = mkOption {
    description = ''
      The set of CUDA packages to be used in the container.

      This option allows you to select a specific version of the CUDA toolkit
      to be installed in the container. This is crucial for ensuring
      compatibility with applications and machine learning frameworks that
      depend on a particular CUDA version.

      The value should be a package set from `pkgs.cudaPackages`. You can find
      available versions by [searching for `cudaPackages` in Nixpkgs](https://ryantm.github.io/nixpkgs/languages-frameworks/cuda/).
    '';
    example = literalExpression ''
      cudaPackages = pkgs.cudaPackages_11_8;
    '';
    type = rootConfig.nix2gpuTypes.cudaPackageSet;
    default = pkgs.cudaPackages_13_0;
    defaultText = literalExpression "pkgs.cudaPackages_13_0";
  };
}
