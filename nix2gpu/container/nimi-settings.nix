{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.nimiSettings = mkOption {
    description = ''
      Bindings to `nimi.settings` to provide for this nix2gpu instance
    '';
    type = types.raw;
    default = { };
  };
}
