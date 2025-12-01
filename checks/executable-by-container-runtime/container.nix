{
  perSystem.nix2gpu."nginx-test" = {
    services.nginx."hello-world-server" = {
      enable = true;
      httpConfig = ''
        server {
          listen 8080 default_server;
          server_name _;

          location / {
            default_type text/plain;
            return 200 "hello world";
          }
        }
      '';
    };

    exposedPorts = {
      "8080/tcp" = { };
    };
  };
}
