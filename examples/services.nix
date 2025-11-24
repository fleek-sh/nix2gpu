{
  # This example shows how one may use
  # [services-flake](https://github.com/juspay/services-flake)
  # config options via the `services` attribute
  perSystem.nix2vast."with-services-flake" = {
    services.clickhouse."clickhouse-example" = {
      enable = true;
      extraConfig = {
        http_port = 9050;
      };
    };

    exposedPorts = {
      "9050/tcp" = { };
    };
  };
}
