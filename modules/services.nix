{
  config,
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (inputs) services-flake process-compose-flake;
  inherit (lib) types mkOption;

  processComposeFlakeModule = process-compose-flake.flakeModule;
  servicesProcessComposeModule = services-flake.processComposeModules.default;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.perContainer = config.flake.lib.mkPerContainerOption (
      { container, ... }:
      {
        options.process-compose = mkOption {
          description = ''
            nix2vast process compose for container ${container.name}.
          '';
          type = types.attrsOf types.unspecified;
          internal = true;
          default = { };
        };
      }
    );
  });

  config.perSystem = _: {
    perContainer =
      { container, ... }:
      {
        imports = [ processComposeFlakeModule ];

        process-compose."${container.name}-services" = {
          imports = [ servicesProcessComposeModule ];

          inherit (container.options) services;
        };
      };
  };
}
