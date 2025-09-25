{ config, ... }:
{
  flake.modules.allPkgs.perSystem =
    with config.perSystem;
    corePkgs
    ++ networkPkgs
    ++ devPkgs
    ++ [
      flake.packages.container-services
      cudaEnv
    ];
}
