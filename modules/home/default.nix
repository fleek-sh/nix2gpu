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
lib.optionalAttrs (inputs ? home-manager) {
  imports = [ home-manager.flakeModules.default ];

  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.nix2gpuHomeConfigurations = mkOption {
      description = ''
        nix2gpu default home configuration.
      '';
      type = types.lazyAttrsOf types.raw;
      internal = true;
    };

    options.perContainer = config.flake.lib.mkPerContainerOption (
      { container, ... }:
      {
        options.homeConfigurations = mkOption {
          description = ''
            nix2gpu home configuration for ${container.name}.
          '';
          type = types.lazyAttrsOf types.raw;
          internal = true;
        };
      }
    );
  };

  config.perSystem =
    { pkgs, ... }:
    {
      nix2gpuHomeConfigurations.default = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./_tmux
          ./_starship
          ./_bash
          ./_config.nix
        ];
      };

      perContainer =
        { container, ... }:
        {
          homeConfigurations."${container.name}-home" = container.options.home;
        };
    };
}
