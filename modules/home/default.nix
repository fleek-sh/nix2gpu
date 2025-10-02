{ inputs, ... }:
let
  inherit (inputs) home-manager;
  homeManagerModule = home-manager.flakeModules.default;
in
{
  perSystem.perContainer =
    { container, ... }:
    {
      imports = [ homeManagerModule ];

      flake.homeConfigurations."${container.name}-home" = container.options.home;
    };
}
