{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.extraCopyToRoot = mkOption {
    description = ''
      extra packages to copy to the root of your container.
    '';
    type = types.listOf types.package;
    default = [ ];
  };
}
