# { lib, flake-parts-lib, ... }:
# let
#   inherit (lib) types mkMerge;
# in
# {
#   options.perContainer = flake-parts-lib.mkPerSystemOption {
#     description = ''
#       A function that iterates all nix2vast containers
#       and produces an expression for that.
#     '';
#     type = types.listOf (types.functionTo (types.lazyAttrsOf types.unspecified));
#   };
#
#   config = let
#     inherit (_module.args) nix2vast perContainer;
#
#     callWithNix2VastConf = fn: (builtins.mapAttrs fn nix2vast);
#   in mkMerge (builtins.map callWithNix2VastConf perContainer);
# }

{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) mkOption types mapAttrs;
  inherit (flake-parts-lib) mkDeferredModuleType;

  mkPerContainerType = mkDeferredModuleType;
in
{
  options = {
    perContainer = mkOption {
      description = ''
        A function that iterates all nix2vast containers
        and produces an expression for that.
      '';
      type = mkPerContainerType (_: {
        # TODO: Figure out what goes here
      });
      apply =
        modules:
        { name, nix2vastConfig }:
        (lib.evalModules {
          inherit modules;
          prefix = [
            "perContainer"
            name
          ];
          specialArgs = { inherit name nix2vastConfig; };
          class = "perContainer";
        }).config;
    };

    allContainers = mkOption {
      type = types.lazyAttrsOf types.unspecified;
      description = "The container-specific config for each container.";
      internal = true;
    };
  };

  config = {
    allContainers = mapAttrs (
      name: nix2vastConfig: config.perContainer { inherit name nix2vastConfig; }
    ) config.nix2vast;

    debug = true;
  };
}
