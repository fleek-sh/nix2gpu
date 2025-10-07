{ lib, config, ... }:
let
  inherit (lib) types mkOption;
  inherit (config) systemConfig;
in
{
  options.home = mkOption {
    description = ''
      the [`home-manager`](https://github.com/nix-community/home-manager)
      configuration to use inside your `nix2vast` container.

      by default a minimal set of useful modern shell packages and
      agenix integration is included for hacking on your machines.
    '';
    type = types.lazyAttrsOf types.raw;
    inherit (systemConfig.homeConfigurations) default;
  };
}
