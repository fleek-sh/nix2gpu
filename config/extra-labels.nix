{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.extraLabels = mkOption {
    description = ''
      extra container labels to set.
    '';
    type = types.attrsOf types.str;
    default = { };
  };
}
