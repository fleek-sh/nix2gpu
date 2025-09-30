{
  perContainer =
    { name, nix2vastConfig, ... }:
    {
      perSystem =
        { pkgs, ... }:
        {
          environment.cudaEnv = pkgs.symlinkJoin {
            name = "${name}-cuda-env";
            paths = with nix2vastConfig.cudaPackages; [
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
    };
}
