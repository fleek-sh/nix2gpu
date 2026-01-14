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
in
{
  _class = "nix2gpu";

  options.cuda = {
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

  config = mkIf cfg.enable {
    # TODO[b7r6]: Pick the right ones
    systemPackages = with cfg.packages; [
      cudatoolkit
      cudnn
      # cusparselt
      libcublas
      libcufile
      libcusparse
      nccl
      pkgs.nvtopPackages.nvidia
    ];

    extraEnv = {
      CUDA_VERSION = cfg.packages.cudaMajorMinorVersion;
      NVIDIA_DISABLE_REQUIRE = "0";
      NVIDIA_DRIVER_CAPABILITIES = "compute,utility,graphics";
      NVIDIA_REQUIRE_CUDA = "cuda>=11.0";
      NVIDIA_VISIBLE_DEVICES = "all";
    };

    extraLabels = {
      "com.nvidia.volumes.needed" = "nvidia_driver";
      "com.nvidia.cuda.version" = cfg.packages.cudatoolkit.version;
    };
  };
}
