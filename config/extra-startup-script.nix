{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.extraStartupScript = mkOption {
    description = ''
      extra commands to run on container startup.
    '';
    type = types.str;
    default = "";
  };
}
