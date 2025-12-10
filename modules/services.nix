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
        builtins.map (name: let
          cfg = config.nix2gpu.${name};
        in {
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
        }) containers
      );
    };
}
