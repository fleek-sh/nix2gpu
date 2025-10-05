{
  lib,
  config,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) mkOption types;

  # TODO: pass to file in config.flake.lib without recursion errors
  inherit (import ./_temp-lib.nix {inherit lib config flake-parts-lib; }) mkTransposedPerContainerModule ;
in
mkTransposedPerContainerModule {
  name = "process-compose";
  option = mkOption {
    type = types.unspecifed;
    default = { };
    description = ''
      Passthru process-compose config
    '';
  };
  file = ./process-compose.nix;
}
