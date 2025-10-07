{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.nixConfig = mkOption {
    description = ''
      a replacement nix.conf to use.
    '';
    type = types.str;
    default = builtins.readFile ../modules/container/config/nix.conf;
  };
}
