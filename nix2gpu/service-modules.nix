{ lib, ... }:
let
  inherit (lib) types mkOption literalExpression;
in
{
  _class = "nix2gpu";

  options.serviceModules = mkOption {
    description = ''
      Extra `services-flake` compatible modules to use in your container.

      This option allows you to import `services-flake` [`multiService`](https://github.com/juspay/services-flake/blob/647bff2c44b42529461f60a7fe07851ff93fb600/nix/lib.nix#L1-L34) modules to configure extra services that can be used inside your container.

      See the `comfyui-service` module in the `nix2gpu` repository for an example.

      To use this, you must first enable the optional `services-flake` 
      integration by adding it to your flake inputs:

      ```nix
      inputs.services-flake.url = "github:juspay/services-flake";
      inputs.process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    '';
    example = literalExpression ''
      serviceModules = [
        ./my-custom-service.nix # See services-flake/nix/services
      ];

      services.my-custom-service."example" = {
        enable = true;
      };
    '';
    type = types.listOf types.path;
    default = [ ];
  };
}
