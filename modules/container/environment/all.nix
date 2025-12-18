{ lib, inputs, ... }:
let
  hasServices = inputs ? services-flake && inputs ? process-compose-flake;
in
{
  perSystem =
    { self', ... }:
    {
      perContainer =
        { config, container, ... }:
        let
          includedPkgs = lib.optionals hasServices [ self'.packages."${container.name}-services" ];
        in
        {
          environment.allPkgs =
            config.environment.corePkgs
            ++ config.environment.networkPkgs
            ++ config.environment.devPkgs
            ++ config.environment.cudaEnv
            ++ includedPkgs
            ++ container.options.systemPackages;
        };
    };
}
