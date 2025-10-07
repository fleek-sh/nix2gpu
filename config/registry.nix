{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.registry = mkOption {
    description = ''
      the container registry to push your images to.
    '';
    type = types.str;
    default = "";
  };
}
