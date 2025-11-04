{ inputs, self, ... }:
{
  perSystem =
    {
      pkgs,
      system,
      lib,
      self',
      ...
    }:
    let
      container = import ../packages/container.nix {
        inherit
          lib
          pkgs
          inputs
          system
          self
          self'
          ;
      };

      validPkgs = lib.filterAttrs (_key: value: lib.isDerivation value) container.passthru;
    in
    # nix2container already ships with functions for
    # copying to docker, etc, we should expose these
    # at least for our container
    {
      packages = validPkgs // {
        inherit container;
      };
    };
}
