{
  lib,
  flake-parts-lib,
  config,
  ...
}:
let
  inherit (lib) types mkOption;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.perContainer = config.flake.lib.mkPerContainerOption (_: {
      options.environment = mkOption {
        description = ''
          nix2gpu environment packages.
        '';
        type = types.attrsOf types.package;
        internal = true;
        default = { };
      };
    });
  });
}
