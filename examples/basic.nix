{ inputs, ... }:
{
  imports = [ inputs.nix2vast.flakeModules.default ];

  perSystem =
    { pkgs, ... }:
    {
      # Try running `nix build .#nix2vast-basic`
      # to build the container.
      #
      # This derivation also exposes some scripts,
      # for example, running `nix build .#nix2vast-basic.copyToGithub`
      # will copy it to it's github registry.
      nix2vast."nix2vast-basic" = {
        services.clickhouse."clickhouse-example" = {
          enable = true;
          extraConfig = {
            http_port = 9050;
          };
        };

        exposedPorts = {
          "9050/tcp" = { };
        };

        cudaPackages = pkgs.cudaPackages_12_8;
        registry = "ghcr.io/fleek-platform";
      };
    };
}
