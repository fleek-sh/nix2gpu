{
  perSystem =
    { pkgs, ... }:
    {
      perContainer =
        { container, ... }:
        {
          environment.cudaEnv = with container.options.cudaPackages; [
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
    };
}
