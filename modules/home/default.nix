{ inputs, ... }:
let
  inherit (inputs) home-manager;
  homeManagerModule = home-manager.flakeModules.default;
in
{
  imports = [ homeManagerModule ];

  perSystem =
  _: {
    perContainer =
      { container, ... }:
      builtins.trace "options: ${container.name}" {
        container.homeConfigurations."${container.name}-home" = container.options.home;
      };
  };
}
