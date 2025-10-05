{ inputs, lib, ... }:
let
  inherit (inputs) services-flake process-compose-flake;

  processComposeFlakeModule = process-compose-flake.flakeModule;
  servicesProcessComposeModule = services-flake.processComposeModules.default;
in
{
  imports = [ processComposeFlakeModule ];

  config.perSystem =
    { config, ... }:
    let
      containers = lib.attrNames config.allContainers;
    in
    {
      process-compose = lib.mergeAttrsList (
        builtins.map (name: {
          "${name}-services" = {
            imports = [ servicesProcessComposeModule ];

            inherit (config.nix2vast.${name}) services;
          };
        }) containers
      );
    };
}
