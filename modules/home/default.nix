{ inputs, ... }:
let
  inherit (inputs) home-manager;
  homeManagerModule = home-manager.flakeModules.default;
in
{
  imports = [ homeManagerModule ];

  config.perContainer =
    { name, nix2vastConfig }:
    {
      flake.homeConfigurations."${name}-home" = nix2vastConfig.home;
    };
}
