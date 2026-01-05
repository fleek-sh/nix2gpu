{ config, ... }:
{
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
}
