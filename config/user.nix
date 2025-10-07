{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.user = mkOption {
    description = ''
      the default user for your container.
    '';
    type = types.str;
    default = "root";
  };
}
