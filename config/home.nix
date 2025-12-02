{ lib, config, ... }:
let
  inherit (lib) types mkOption;
  inherit (config) systemConfig;
in
{
  options.home = mkOption {
    description = ''
      The `home-manager` configuration for the container's user environment.

      This option allows you to define the user's home environment using
      [`home-manager`](https://github.com/nix-community/home-manager)
      .You can configure everything from shell aliases and environment
      variables to user services and application settings.

      By default, a minimal set of useful modern shell packages
      is included to provide a comfortable and secure hacking
      environment on your machines.

      To use this, you must first enable the optional `home-manager` 
      integration by adding it to your flake inputs:

      ```nix
      inputs.home-manager = {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      ```
    '';
    example = ''
      home = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./home
        ];
      };
    '';
    type = types.lazyAttrsOf types.raw;
    inherit (systemConfig.homeConfigurations) default;
    defaultText = ''
      A sample home manager config with some nice defaults
      from nix2gpu
    '';
  };
}
