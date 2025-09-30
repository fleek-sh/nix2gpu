{ inputs, ... }:
let
  inherit (inputs) services-flake process-compose-flake;

  processComposeFlakeModule = process-compose-flake.flakeModule;
  servicesProcessComposeModule = services-flake.processComposeModules.default;
in
{
  perContainer =
    { container, ... }:
    {
      imports = [ processComposeFlakeModule ];

      process-compose."${container.name}-services" = {
        imports = [ servicesProcessComposeModule ];

        inherit (container.options) services;
      };
    };
}
