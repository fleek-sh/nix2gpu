{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      nix2gpu."http-test" = {
        services."hello-world-server" = {
          process.argv = [ (lib.getExe pkgs.http-server) ];
        };

        exposedPorts = {
          "8080/tcp" = { };
        };
      };
    };
}
