{
  # This example shows how one may use
  # [services-flake](https://github.com/juspay/services-flake)
  # config options via the `services` attribute
  perSystem =
    { pkgs, ... }:
    {
      nix2gpu."with-services" = {
        services."ghostunnel-example" = {
          imports = [ pkgs.ghostunnel.services ];
          ghostunnel = {
            listen = "0.0.0.0:443";
            cert = "/root/service-cert.pem";
            key = "/root/service-key.pem";
            disableAuthentication = true;
            target = "backend:80";
            unsafeTarget = true;
          };
        };

        exposedPorts = {
          "9050/tcp" = { };
        };
      };
    };
}
