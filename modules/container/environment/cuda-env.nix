{
  config,
  ...
}:
let
  cudaPackages = config.nix2vast.cudaPackages;
in
{
  flake.packages.cudaEnv =
    { pkgs, ... }:
    pkgs.symlinkJoin {
      name = "cuda-env";
      paths = with pkgs; [
        cudaPackages.cudatoolkit
        cudaPackages.cudnn
        cudaPackages.cusparselt
        cudaPackages.libcublas
        cudaPackages.libcufile
        cudaPackages.libcusparse
        cudaPackages.nccl
        nvtopPackages.nvidia
      ];

      postBuild = ''
        rm -f $out/LICENSE
        rm -f $out/version.txt
      '';
    };
}
