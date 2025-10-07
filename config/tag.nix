{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.tag = mkOption {
    description = ''
      the tag to use for your container
    '';
    type = types.str;
    default = "latest";
  };
}
