{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs) services-flake process-compose-flake;
  inherit (lib) types;

  processComposeFlakeModule = process-compose-flake.flakeModule;
  servicesProcessComposeModule = services-flake.processComposeModules.default;
in
{
  imports = [
    processComposeFlakeModule
  ];

  options.nix2vast.services = lib.mkOption {
    description = ''
      the [`services-flake`](https://github.com/juspay/services-flake)
      configuration to use inside your `nix2vast` container.

      when your container is launched it boots into a
      [process-compose](https://github.com/F1bonacc1/process-compose]
      interface running all services specificed. 

      this can be useful for running your own web servers or things
      like nginx.
    '';
    type = types.attrsOf servicesProcessComposeModule.options.type;
    default = { };
  };

  config = {
    perSystem =
      { ... }:
      {
        process-compose."container-services" = {
          imports = [
            servicesProcessComposeModule
          ];
        };
      };

    nix2vast.services = {
      nginx."nginx-hello-world" = {
        enable = true;
        httpConfig = ''
          server {
              listen 8080 default_server;
              listen [::]:8080 default_server;
              server_name _;

              root /root;

              location / {
                  add_header Content-Type text/plain;
                  return 200 "hello world";
              }
          }
        '';
      };
    };
  };
}
