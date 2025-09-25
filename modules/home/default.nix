{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (inputs) home-manager;
  homeManagerModule = home-manager.flakeModules.default;
in
{
  options.nix2vast.home = lib.mkOption {
    description = ''
      the [`home-manager`](https://github.com/nix-community/home-manager)
      configuration to use inside your `nix2vast` container.

      by default a minimal set of useful modern shell packages and
      agenix integration is included for hacking on your machines.
    '';
    type = homeManagerModule.options.flake.homeConfigurations.type;
  };

  config.nix2vast.perSystem =
    { pkgs, ... }:
    {
      home = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs;
          nix2vast = config.packages.${pkgs.system};
        };
        modules = [
          inputs.agenix.homeManagerModules.default
          ./tmux
          ./starship
          ./bash
          ./agenix
        ];
      };
    };
}
