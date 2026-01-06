_:
{
  perSystem =
    _:
    {
      nix2gpu."nginx-test" = {
        # services."hello-world-server" = {
        #   imports = [ (lib.modules.importApply ../../services/nginx.nix { inherit pkgs; }) ];
        #   nginx.httpConfig = ''
        #     server {
        #       listen 8080 default_server;
        #       server_name _;
        #
        #       location / {
        #         default_type text/plain;
        #         return 200 "hello world";
        #       }
        #     }
        #   '';
        # };

        exposedPorts = {
          "8080/tcp" = { };
        };
      };
    };
}
