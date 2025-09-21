_: {
  perSystem = _: {
    process-compose.container-services = {
      services.nginx."nginx-service" = {
        enable = true;
        httpConfig = ''
          server {
              listen 8080 default_server;
              listen [::]:8080 default_server;
              server_name _;

              location = /secret {
                  default_type text/plain;
                  alias /root/deploy.json;
              }

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
