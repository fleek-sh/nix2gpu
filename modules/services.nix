{ inputs, lib, ... }:
let
  inherit (inputs) services-flake process-compose-flake import-tree;
  inherit (inputs.services-flake.lib) multiService;

  processComposeFlakeModule = process-compose-flake.flakeModule;
  servicesProcessComposeModule = services-flake.processComposeModules.default;
in
lib.optionalAttrs (inputs ? services-flake && inputs ? process-compose-flake) {
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
            imports = [
              servicesProcessComposeModule
            ]
            ++ lib.pipe ../services [
              (import-tree.withLib lib).leafs
              (map multiService)
            ];

            inherit (config.nix2gpu.${name}) services;
          };
        }) containers
      );
    };
}
