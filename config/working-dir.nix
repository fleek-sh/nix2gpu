{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.workingDir = mkOption {
    description = ''
      the working directory for your container to start in.
    '';
    type = types.str;
    default = "/root";
  };
}
