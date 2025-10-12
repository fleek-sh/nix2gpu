{ inputs, ... }:
let
  inherit (inputs) home-manager;
in
{
  # This example shows how one may use
  # [custom home manager](https://github.com/juspay/services-flake)
  # config options via the `home` attribute
  perSystem =
    { pkgs, ... }:
    {
      nix2vast."custom-home" = {
        home = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./_home.nix ];
        };
      };
    };
}
