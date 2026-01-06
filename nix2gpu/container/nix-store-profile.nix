{ pkgs, ... }:
{
  config.nimiSettings.container.copyToRoot = pkgs.runCommand "nix-store-profile" { } ''
    mkdir -p $out/root
    mkdir -p $out/root/.nix-defexpr
    touch $out/root/.nix-channels
  '';
}
