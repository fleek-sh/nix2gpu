{
  lib,
  config,
  self',
  name,
  ...
}:
let
  inherit (lib) types mkOption literalExpression;

  mkIfElse =
    cond: do: otherwise:
    lib.mkMerge [
      (lib.mkIf cond do)
      (lib.mkIf (!cond) otherwise)
    ];

  cfg = config.services;
in
{
  options.services = mkOption {
    description = ''
      The `services-flake` configuration for the container.

      This option allows you to define and manage long-running services within
      the container using the [`services-flake`](https://github.com/juspay/services-flake)
      framework. When the container starts, it will launch a
      [process-compose](https://github.com/F1bonacc1/process-compose)
      instance that manages all the services you define here.

      This is a powerful way to run web servers, databases, or any other
      background processes your application might need.

      > If this option is left blank no services will be started and 
      > an interactive bash session will open instead.

      To use this, you must first enable the optional `services-flake` 
      integration by adding it to your flake inputs:

      ```nix
      inputs.services-flake.url = "github:juspay/services-flake";
      inputs.process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    '';
    example = literalExpression ''
      exposedPorts = {
        "22/tcp" = { };
        "8888/tcp" = { };
      };

      services.nginx."nginx-example" = {
        enable = true;
        httpConfig = '''
          server {
            listen 8888;  
            include ../../importedconfig.conf;
          };
        };
      };
    '';
    type = types.lazyAttrsOf types.raw;
    default = { };
  };

  config =
    mkIfElse (cfg != { })
      {
        systemPackages = [ self'.packages."${name}-services" ];

        extraStartupScript = ''
          if [[ $- != *i* ]] || ! [ -t 0 ]; then
            export PC_DISABLE_TUI=true
          fi

          echo "[nix2gpu] starting services..."
          ${name}-services
        '';
      }
      {
        extraStartupScript = ''
          echo "[nix2gpu] waiting for user interaction over ssh..."
          sleep infinity
        '';
      };
}
