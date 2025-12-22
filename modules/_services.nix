{ rootInputs, ... }:
{ lib, ... }:
let
  inherit (rootInputs) services-flake process-compose-flake import-tree;
  inherit (rootInputs.services-flake.lib) multiService;

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
        builtins.map (
          name:
          let
            cfg = config.nix2gpu.${name};
          in
          {
            "${name}-services" = {
              imports = [
                servicesProcessComposeModule
              ]
              ++ lib.pipe ../services [
                (import-tree.withLib lib).leafs
                (internalServices: internalServices ++ cfg.serviceModules)
                (map multiService)
              ];

              inherit (cfg) services;
            };
          }
        ) containers
      );
    };
}
