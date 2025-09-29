{ inputs, ... }:
let
  inherit (inputs) services-flake process-compose-flake;

  processComposeFlakeModule = process-compose-flake.flakeModule;
  servicesProcessComposeModule = services-flake.processComposeModules.default;
in
{
  perContainer =
    { name, nix2vastConfig }:
    {
      imports = [ processComposeFlakeModule ];

      process-compose."${name}-services" = {
        imports = [ servicesProcessComposeModule ];

        inherit (nix2vastConfig) services;
      };
    };
}
