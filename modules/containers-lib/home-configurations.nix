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
  name = "homeConfigurations";
  option = mkOption {
    type = types.unspecifed;
    default = { };
    description = ''
      Passthru home manager config
    '';
  };
  file = ./home-configurations.nix;
}
