{ inputs, ... }:
let
  inherit (inputs) home-manager;
in
{
  # This example shows how one may use
  # home-manager config options via the `home` attribute
  perSystem =
    { pkgs, ... }:
    {
      nix2gpu."custom-home" = {
        home = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./_home.nix ];
        };
      };
    };
}
