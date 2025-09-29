{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types mkMerge;
  inherit (config) nix2vast;
  perContainer = config.perContainer or [ ];

  callWithNix2VastConf = fn: (builtins.mapAttrs fn nix2vast);

  config = mkMerge (builtins.map callWithNix2VastConf perContainer);
in
{
  options.perContainer = flake-parts-lib.mkPerSystemOption {
    description = ''
      A function that iterates all nix2vast containers
      and produces an expression for that.
    '';
    type = types.listOf (types.functionTo (types.lazyAttrsOf types.unspecified));
  };

  config = builtins.trace perContainer config;
}
