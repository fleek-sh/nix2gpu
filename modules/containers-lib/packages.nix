{
  lib,
  config,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) mkOption types;

  # TODO: pass to file in config.flake.lib without recursion errors
  inherit (import ./_temp-lib.nix { inherit lib config flake-parts-lib; })
    mkTransposedPerContainerModule
    ;
in
mkTransposedPerContainerModule {
  name = "packages";
  option = mkOption {
    type = types.lazyAttrsOf types.package;
    default = { };
    description = ''
      An attribute set of packages to be built by [`nix build`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-build.html).

      `nix build .#<name>` will build `packages.<name>`.
    '';
  };
  file = ./packages.nix;
}
