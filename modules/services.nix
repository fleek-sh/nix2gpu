{
  config,
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (inputs) services-flake process-compose-flake;

  processComposeFlakeModule = process-compose-flake.flakeModule;
  servicesProcessComposeModule = services-flake.processComposeModules.default;
in
{
  imports = [ processComposeFlakeModule ];

  perSystem = _: {
    perContainer =
      { container, ... }:
      {
        process-compose."${container.name}-services" = {
          imports = [ servicesProcessComposeModule ];

          inherit (container.options) services;
        };
      };
  };
}
