{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  _class = "nix2gpu";

  options.services = mkOption {
    description = ''
      Services to run inside the `nix2gpu` container via `Nimi`.

      Each attribute defines a named NixOS modular service (Nix 25.11): import
      a service module and override its options per instance. This keeps service
      definitions composable and reusable across projects.

      For the upstream model, see the NixOS manual section on
      [Modular Services](https://nixos.org/manual/nixos/unstable/#modular-services).
    '';
    type = types.lazyAttrsOf types.deferredModule;
    default = { };
    visible = "shallow";
  };
}
