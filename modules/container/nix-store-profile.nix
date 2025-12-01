{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types mkOption;
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options.perSystem = mkPerSystemOption {
    options.nix2gpuNixStoreProfile = mkOption {
      description = ''
        nix2gpu generated nix store profile.
      '';
      type = types.package;
      internal = true;
    };
  };

  config.perSystem =
    { pkgs, ... }:
    {
      nix2gpuNixStoreProfile = pkgs.runCommand "nix-store-profile" { } ''
        mkdir -p $out/root
        mkdir -p $out/root/.nix-defexpr
        touch $out/root/.nix-channels
      '';
    };
}
