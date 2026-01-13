{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    literalExpression
    types
    ;

  cfg = config.cuda;

  cudaType = types.submodule {
    options = {
      enable = mkOption {
        description = ''
          If `nix2gpu`'s cuda integration should be enabled or not
        '';
        example = literalExpression ''
          cudaPackages = pkgs.cudaPackages_11_8;
        '';
        type = types.bool;
        default = true;
      };
      packages = mkOption {
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
          cuda.packages = pkgs.cudaPackages_11_8;
        '';
        type = config.nix2gpuTypes.cudaPackageSet;
        default = pkgs.cudaPackages_13_0;
        defaultText = literalExpression "pkgs.cudaPackages_13_0";
      };
    };
  };
in
{
  _class = "nix2gpu";

  options.cuda = {
    description = ''
      Cuda configuration options for `nix2gpu`.

      Allows you to configure the behaviour of `cuda` in a `nix2gpu` context.
    '';
    example = literalExpression ''
      cuda.enable = true;
      cuda.packages = pkgs.cudaPackages_11_8;
    '';
    type = cudaType;
    default = { };
  };

  config = mkIf cfg.enable {
    # TODO[b7r6]: Pick the right ones
    systemPackages = with config.cudaPackages; [
      cudatoolkit
      cudnn
      # cusparselt
      libcublas
      libcufile
      libcusparse
      nccl
      pkgs.nvtopPackages.nvidia
    ];
  };
}
