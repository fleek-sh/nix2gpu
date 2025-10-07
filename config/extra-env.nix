{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.extraEnv = mkOption {
    description = ''
      extra environment variables to set inside your container.
    '';
    type = types.listOf types.str;
    default = [ ];
  };
}
