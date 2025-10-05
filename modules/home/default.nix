{ inputs, ... }:
let
  inherit (inputs) home-manager;
in
{
  imports = [ home-manager.flakeModules.default ];

  perSystem = {pkgs, ...}: {
    flake.homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        ./_tmux
        ./_starship
        ./_bash
        ./_agenix
      ];
    };

    perContainer =
      { container, ... }:
      {
        homeConfigurations."${container.name}-home" = container.options.home;
      };
  };
}
