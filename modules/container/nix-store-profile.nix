{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.nix2vastNixStoreProfile = mkOption {
      description = ''
        nix2vast generated nix store profile.
      '';
      type = types.package;
      internal = true;
    };
  });

  config.perSystem =
    { pkgs, ... }:
    {
      nix2vastNixStoreProfile = pkgs.runCommand "nix-store-profile" { } ''
        mkdir -p $out/root
        mkdir -p $out/root/.nix-defexpr
        touch $out/root/.nix-channels
      '';
    };
}
