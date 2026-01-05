{ lib, pkgs, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.nix2gpuNixStoreProfile = mkOption {
    description = ''
      nix2gpu generated nix store profile.
    '';
    type = types.package;
    internal = true;
  };

  config.nix2gpuNixStoreProfile = pkgs.runCommand "nix-store-profile" { } ''
    mkdir -p $out/root
    mkdir -p $out/root/.nix-defexpr
    touch $out/root/.nix-channels
  '';
}
