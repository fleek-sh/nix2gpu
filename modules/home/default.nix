{
  config,
  lib,
  inputs,
  flake-parts-lib,
  ...
}:
let
  inherit (inputs) home-manager;
  homeManagerModule = home-manager.flakeModules.default;
in
{
  options.nix2vast.home = flake-parts-lib.mkPerSystemOption (
    { pkgs, ... }:
    {
      description = ''
        the [`home-manager`](https://github.com/nix-community/home-manager)
        configuration to use inside your `nix2vast` container.

        by default a minimal set of useful modern shell packages and
        agenix integration is included for hacking on your machines.
      '';
      type = homeManagerModule.options.flake.homeConfigurations.type;
      default = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [
          ./_tmux
          ./_starship
          ./_bash
          ./_agenix
        ];
      };
  });
}
