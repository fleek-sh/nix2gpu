{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types mkMerge;
in
{
  options.perContainer = flake-parts-lib.mkPerSystemOption {
    description = ''
      A function that iterates all nix2vast containers
      and produces an expression for that.
    '';
    type = types.listOf (types.functionTo (types.lazyAttrsOf types.unspecified));
    apply =
      perContainerDecls:
      mkMerge (builtins.map (fn: builtins.mapAttrs fn config.nix2vast) perContainerDecls);
  };
}
