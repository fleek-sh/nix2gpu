_:
{
  # This example shows how one may use
  # [services-flake](https://github.com/juspay/services-flake)
  # config options via the `services` attribute
  perSystem =
    _:
    {
      nix2gpu."with-services" = {
        # services."clickhouse-example" = {
        #   imports = [ (lib.modules.importApply ../services/clickhouse-keeper.nix { inherit pkgs; }) ];
        #   clickhouse-keeper.tcpPort = 9050;
        # };

        exposedPorts = {
          "9050/tcp" = { };
        };
      };
    };
}
