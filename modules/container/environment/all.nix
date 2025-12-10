{ lib, inputs, ... }:
let
  hasServices = inputs ? services-flake && inputs ? process-compose-flake;
in
{
  perSystem =
    { self', pkgs, ... }:
    {
      perContainer =
        { config, container, ... }:
        let
          includedEnv = with config.environment; [
            corePkgs
            networkPkgs
            devPkgs
            cudaEnv
          ];

          includedPkgs = lib.optionals hasServices [ self'.packages."${container.name}-services" ];
        in
        {
          environment.allPkgs = pkgs.symlinkJoin {
            name = "all-pkgs";
            paths = includedEnv ++ includedPkgs;
          };
        };
    };
}
