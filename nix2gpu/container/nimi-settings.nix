{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.nimiSettings = mkOption {
    description = ''
      Bindings to `nimi.settings` for this nix2gpu instance.

      Use this to tune Nimi runtime behavior (restart policy, logging, startup
      hooks, and container build settings) beyond the defaults provided by
      nix2gpu.
    '';
    type = types.deferredModule;
    default = { };
  };
}
