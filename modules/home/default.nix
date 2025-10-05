{
  inputs,
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types mkOption;
  inherit (inputs) home-manager;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.perContainer = config.flake.lib.mkPerContainerOption (
      { container, ... }:
      {
        options.homeConfigurations = mkOption {
          description = ''
            nix2vast home configuration for ${container.name}.
          '';
          type = types.lazyAttrsOf types.raw;
          internal = true;
        };
      }
    );
  });

  imports = [ home-manager.flakeModules.default ];

  config = {
    perSystem =
      { pkgs, ... }:
      {
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
  };
}
