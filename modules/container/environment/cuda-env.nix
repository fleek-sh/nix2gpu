{ config, ... }:
let
  inherit (config.nix2vast) cudaPackages;
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.cudaEnv = pkgs.symlinkJoin {
        name = "cuda-env";
        paths = with cudaPackages; [
          cudatoolkit
          cudnn
          cusparselt
          libcublas
          libcufile
          libcusparse
          nccl
          pkgs.nvtopPackages.nvidia
        ];

        postBuild = ''
          rm -f $out/LICENSE
          rm -f $out/version.txt
        '';
      };
    };
}
