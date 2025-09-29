{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types;
in
{
  options.nixStoreProfile = flake-parts-lib.mkPerSystemOption {
    description = ''
      nix2vast generated nix store profile.
    '';
    type = types.package;
    internal = true;
  };

  config.nixStoreProfile =
    { pkgs, ... }:
    pkgs.runCommand "nix-store-profile" { } ''
      mkdir -p $out/root
      mkdir -p $out/root/.nix-defexpr
      touch $out/root/.nix-channels
    '';
}
