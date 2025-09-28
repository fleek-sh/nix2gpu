{ config, ... }:
let
  pkgSet = with config; [
    corePkgs
    networkPkgs
    devPkgs
    cudaEnv
  ];

  pkgSetPerSystem = { system, ... }: builtins.map (pkg: pkg system) pkgSet;
in
{
  flake.modules.allPkgs =
    { system, ... }@perSystemArgs:
    (pkgSetPerSystem perSystemArgs)
    ++ [
      config.packages.${system}.container-services
    ];
}
