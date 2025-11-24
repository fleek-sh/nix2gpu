{
  perSystem =
    { pkgs, ... }:
    {
      perContainer =
        { container, ... }:
        {
          environment.cudaEnv = pkgs.symlinkJoin {
            name = "${container.name}-cuda-env";
            paths = with container.options.cudaPackages; [
              cudatoolkit
              cudnn
              # cusparselt
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
