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

              root /root;

              location /agenix/ {
                  autoindex on;
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
