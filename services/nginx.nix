{ pkgs, ... }:
{ lib, config, ... }:
let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    literalExpression
    optional
    optionalAttrs
    optionalString
    optionals
    concatMapStringsSep
    concatStringsSep
    flip
    mapAttrsToList
    mapAttrs
    filterAttrs
    filter
    any
    attrValues
    sortProperties
    all
    count
    id
    mkIf
    mkMerge
    ;

  cfg = config.nginx;

  compressMimeTypes = [
    "application/atom+xml"
    "application/geo+json"
    "application/javascript"
    "application/json"
    "application/ld+json"
    "application/manifest+json"
    "application/rdf+xml"
    "application/vnd.ms-fontobject"
    "application/wasm"
    "application/x-rss+xml"
    "application/x-web-app-manifest+json"
    "application/xhtml+xml"
    "application/xliff+xml"
    "application/xml"
    "font/collection"
    "font/otf"
    "font/ttf"
    "image/bmp"
    "image/svg+xml"
    "image/vnd.microsoft.icon"
    "text/cache-manifest"
    "text/calendar"
    "text/css"
    "text/csv"
    "text/javascript"
    "text/markdown"
    "text/plain"
    "text/vcard"
    "text/vnd.rim.location.xloc"
    "text/vtt"
    "text/x-component"
    "text/xml"
  ];

  defaultFastcgiParams = {
    SCRIPT_FILENAME = "$document_root$fastcgi_script_name";
    QUERY_STRING = "$query_string";
    REQUEST_METHOD = "$request_method";
    CONTENT_TYPE = "$content_type";
    CONTENT_LENGTH = "$content_length";

    SCRIPT_NAME = "$fastcgi_script_name";
    REQUEST_URI = "$request_uri";
    DOCUMENT_URI = "$document_uri";
    DOCUMENT_ROOT = "$document_root";
    SERVER_PROTOCOL = "$server_protocol";
    REQUEST_SCHEME = "$scheme";
    HTTPS = "$https if_not_empty";

    GATEWAY_INTERFACE = "CGI/1.1";
    SERVER_SOFTWARE = "nginx/$nginx_version";

    REMOTE_ADDR = "$remote_addr";
    REMOTE_PORT = "$remote_port";
    SERVER_ADDR = "$server_addr";
    SERVER_PORT = "$server_port";
    SERVER_NAME = "$server_name";

    REDIRECT_STATUS = "200";
  };

  recommendedProxyConfig = pkgs.writeText "nginx-recommended-proxy_set_header-headers.conf" ''
    proxy_set_header        Host $host;
    proxy_set_header        X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Proto $scheme;
    proxy_set_header        X-Forwarded-Host $host;
    proxy_set_header        X-Forwarded-Server $hostname;
  '';

  proxyCachePathConfig = concatStringsSep "\n" (
    mapAttrsToList (name: proxyCachePath: ''
      proxy_cache_path ${
        concatStringsSep " " [
          "/var/cache/nginx/${name}"
          "keys_zone=${proxyCachePath.keysZoneName}:${proxyCachePath.keysZoneSize}"
          "levels=${proxyCachePath.levels}"
          "use_temp_path=${if proxyCachePath.useTempPath then "on" else "off"}"
          "inactive=${proxyCachePath.inactive}"
          "max_size=${proxyCachePath.maxSize}"
        ]
      };
    '') (filterAttrs (_: conf: conf.enable) cfg.proxyCachePath)
  );

  toUpstreamParameter =
    key: value:
    if builtins.isBool value then lib.optionalString value key else "${key}=${toString value}";

  upstreamConfig = toString (
    flip mapAttrsToList cfg.upstreams (
      name: upstream: ''
        upstream ${name} {
          ${toString (
            flip mapAttrsToList upstream.servers (
              name: server: ''
                server ${name} ${concatStringsSep " " (mapAttrsToList toUpstreamParameter server)};
              ''
            )
          )}
          ${upstream.extraConfig}
        }
      ''
    )
  );

  commonHttpConfig = ''
    include ${cfg.defaultMimeTypes};
    types_hash_max_size ${toString cfg.typesHashMaxSize};

    include ${cfg.package}/conf/fastcgi.conf;
    include ${cfg.package}/conf/uwsgi_params;

    default_type application/octet-stream;
  '';

  locationOptions =
    { lib, config }:
    with lib;
    {
      options = {
        basicAuth = mkOption {
          type = types.attrsOf types.str;
          default = { };
          example = literalExpression ''
            {
              user = "password";
            };
          '';
          description = ''
            Basic Auth protection for a location.

            WARNING: This is implemented to store the password in plain text in the
            Nix store.
          '';
        };

        basicAuthFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = ''
            Basic Auth password file for a location.
            Can be created by running {command}`nix-shell --packages apacheHttpd --run 'htpasswd -B -c FILENAME USERNAME'`.
          '';
        };

        proxyPass = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "http://www.example.org/";
          description = ''
            Adds proxy_pass directive and sets recommended proxy headers if
            recommendedProxySettings is enabled.
          '';
        };

        proxyWebsockets = mkOption {
          type = types.bool;
          default = false;
          example = true;
          description = ''
            Whether to support proxying websocket connections with HTTP/1.1.
          '';
        };

        uwsgiPass = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "unix:/run/example/example.sock";
          description = ''
            Adds uwsgi_pass directive and sets recommended proxy headers if
            recommendedUwsgiSettings is enabled.
          '';
        };

        index = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "index.php index.html";
          description = ''
            Adds index directive.
          '';
        };

        tryFiles = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "$uri =404";
          description = ''
            Adds try_files directive.
          '';
        };

        root = mkOption {
          type = types.nullOr types.path;
          default = null;
          example = "/your/root/directory";
          description = ''
            Root directory for requests.
          '';
        };

        alias = mkOption {
          type = types.nullOr types.path;
          default = null;
          example = "/your/alias/directory";
          description = ''
            Alias directory for requests.
          '';
        };

        return = mkOption {
          type =
            with types;
            nullOr (oneOf [
              str
              int
            ]);
          default = null;
          example = "301 http://example.com$request_uri";
          description = ''
            Adds a return directive, for e.g. redirections.
          '';
        };

        fastcgiParams = mkOption {
          type = types.attrsOf (types.either types.str types.path);
          default = { };
          description = ''
            FastCGI parameters to override.  Unlike in the Nginx
            configuration file, overriding only some default parameters
            won't unset the default values for other parameters.
          '';
        };

        extraConfig = mkOption {
          type = types.lines;
          default = "";
          description = ''
            These lines go to the end of the location verbatim.
          '';
        };

        priority = mkOption {
          type = types.int;
          default = 1000;
          description = ''
            Order of this location block in relation to the others in the vhost.
            The semantics are the same as with `lib.mkOrder`. Smaller values have
            a greater priority.
          '';
        };

        recommendedProxySettings = mkOption {
          type = types.bool;
          default = config.nginx.recommendedProxySettings;
          defaultText = literalExpression "config.nginx.recommendedProxySettings";
          description = ''
            Enable recommended proxy settings.
          '';
        };

        recommendedUwsgiSettings = mkOption {
          type = types.bool;
          default = config.nginx.recommendedUwsgiSettings;
          defaultText = literalExpression "config.nginx.recommendedUwsgiSettings";
          description = ''
            Enable recommended uwsgi settings.
          '';
        };
      };
    };

  vhostOptions =
    { config, lib }:
    with lib;
    {
      options = {
        serverName = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Name of this virtual host. Defaults to attribute name in virtualHosts.
          '';
          example = "example.org";
        };

        serverAliases = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [
            "www.example.org"
            "example.org"
          ];
          description = ''
            Additional names of virtual hosts served by this virtual host configuration.
          '';
        };

        listen = mkOption {
          type =
            with types;
            listOf (submodule {
              options = {
                addr = mkOption {
                  type = str;
                  description = "Listen address.";
                };
                port = mkOption {
                  type = types.nullOr port;
                  description = ''
                    Port number to listen on.
                    If unset and the listen address is not a socket then nginx defaults to 80.
                  '';
                  default = null;
                };
                ssl = mkOption {
                  type = bool;
                  description = "Enable SSL.";
                  default = false;
                };
                proxyProtocol = mkOption {
                  type = bool;
                  description = "Enable PROXY protocol.";
                  default = false;
                };
                extraParameters = mkOption {
                  type = listOf str;
                  description = "Extra parameters of this listen directive.";
                  default = [ ];
                  example = [
                    "backlog=1024"
                    "deferred"
                  ];
                };
              };
            });
          default = [ ];
          example = [
            {
              addr = "195.154.1.1";
              port = 443;
              ssl = true;
            }
            {
              addr = "192.154.1.1";
              port = 80;
            }
            { addr = "unix:/var/run/nginx.sock"; }
          ];
          description = ''
            Listen addresses and ports for this virtual host.
            IPv6 addresses must be enclosed in square brackets.
            Note: this option overrides `addSSL`
            and `onlySSL`.

            If you only want to set the addresses manually and not
            the ports, take a look at `listenAddresses`.
          '';
        };

        listenAddresses = mkOption {
          type = with types; listOf str;

          description = ''
            Listen addresses for this virtual host.
            Compared to `listen` this only sets the addresses
            and the ports are chosen automatically.
          '';
          default = [ ];
          example = [
            "127.0.0.1"
            "[::1]"
          ];
        };

        addSSL = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable HTTPS in addition to plain HTTP. This will set defaults for
            `listen` to listen on all interfaces on the respective default
            ports (80, 443).
          '';
        };

        onlySSL = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable HTTPS and reject plain HTTP connections. This will set
            defaults for `listen` to listen on all interfaces on port 443.
          '';
        };

        forceSSL = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to add a separate nginx server block that redirects (defaults
            to 301, configurable with `redirectCode`) all plain HTTP traffic to
            HTTPS. This will set defaults for `listen` to listen on all interfaces
            on the respective default ports (80, 443), where the non-SSL listens
            are used for the redirect vhosts.
          '';
        };

        rejectSSL = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to listen for and reject all HTTPS connections to this vhost. Useful in
            default server blocks to avoid serving the certificate for another vhost.
          '';
        };

        kTLS = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable kTLS support.
            Implementing TLS in the kernel (kTLS) improves performance by significantly
            reducing the need for copying operations between user space and the kernel.
            Required Nginx version 1.21.4 or later.
          '';
        };

        sslCertificate = mkOption {
          type = types.nullOr types.path;
          default = null;
          example = "/var/host.cert";
          description = "Path to server SSL certificate.";
        };

        sslCertificateKey = mkOption {
          type = types.nullOr types.path;
          default = null;
          example = "/var/host.key";
          description = "Path to server SSL certificate key.";
        };

        sslTrustedCertificate = mkOption {
          type = types.nullOr types.path;
          default = null;
          example = literalExpression ''"''${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"'';
          description = "Path to root SSL certificate for stapling and client certificates.";
        };

        http2 = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether to enable the HTTP/2 protocol.
            Note that (as of writing) due to nginx's implementation, to disable
            HTTP/2 you have to disable it on all vhosts that use a given
            IP address / port.
            If there is one server block configured to enable http2, then it is
            enabled for all server blocks on this IP.
            See <https://stackoverflow.com/a/39466948/263061>.
          '';
        };

        http3 = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether to enable the HTTP/3 protocol.
            This requires activating the QUIC transport protocol
            `nginx.virtualHosts.<name>.quic = true;`.
            Note that HTTP/3 support is experimental and *not* yet recommended for production.
            Read more at <https://quic.nginx.org/>
            HTTP/3 availability must be manually advertised, preferably in each location block.
          '';
        };

        http3_hq = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable the HTTP/0.9 protocol negotiation used in QUIC interoperability tests.
            This requires activating the QUIC transport protocol
            `nginx.virtualHosts.<name>.quic = true;`.
            Note that special application protocol support is experimental and *not* yet recommended for production.
            Read more at <https://quic.nginx.org/>
          '';
        };

        quic = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable the QUIC transport protocol.
            Note that QUIC support is experimental and
            *not* yet recommended for production.
            Read more at <https://quic.nginx.org/>
          '';
        };

        reuseport = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Create an individual listening socket.
            It is required to specify only once on one of the hosts.
          '';
        };

        root = mkOption {
          type = types.nullOr types.path;
          default = null;
          example = "/data/webserver/docs";
          description = ''
            The path of the web root directory.
          '';
        };

        default = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Makes this vhost the default.
          '';
        };

        extraConfig = mkOption {
          type = types.lines;
          default = "";
          description = ''
            These lines go to the end of the vhost verbatim.
          '';
        };

        globalRedirect = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "newserver.example.org";
          description = ''
            If set, all requests for this host are redirected (defaults to 301,
            configurable with `redirectCode`) to the given hostname.
          '';
        };

        redirectCode = mkOption {
          type = types.ints.between 300 399;
          default = 301;
          example = 308;
          description = ''
            HTTP status used by `globalRedirect` and `forceSSL`. Possible usecases
            include temporary (302, 307) redirects, keeping the request method and
            body (307, 308), or explicitly resetting the method to GET (303).
            See <https://developer.mozilla.org/en-US/docs/Web/HTTP/Redirections>.
          '';
        };

        basicAuth = mkOption {
          type = types.attrsOf types.str;
          default = { };
          example = literalExpression ''
            {
              user = "password";
            };
          '';
          description = ''
            Basic Auth protection for a vhost.

            WARNING: This is implemented to store the password in plain text in the
            Nix store.
          '';
        };

        basicAuthFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = ''
            Basic Auth password file for a vhost.
            Can be created by running {command}`nix-shell --packages apacheHttpd --run 'htpasswd -B -c FILENAME USERNAME'`.
          '';
        };

        locations = mkOption {
          type = types.attrsOf (
            types.submodule (locationOptions {
              inherit lib config;
            })
          );
          default = { };
          example = literalExpression ''
            {
              "/" = {
                proxyPass = "http://localhost:3000";
              };
            };
          '';
          description = "Declarative location config";
        };
      };
    };

  mkHtpasswd =
    name: authDef:
    pkgs.writeText "${name}.htpasswd" (
      concatStringsSep "\n" (
        mapAttrsToList (user: password: ''
          ${user}:{PLAIN}${password}
        '') authDef
      )
    );

  mkBasicAuth =
    name: zone:
    optionalString (zone.basicAuthFile != null || zone.basicAuth != { }) (
      let
        authFile =
          if zone.basicAuthFile != null then zone.basicAuthFile else mkHtpasswd name zone.basicAuth;
      in
      ''
        auth_basic secured;
        auth_basic_user_file ${authFile};
      ''
    );

  mkLocations =
    locations:
    concatStringsSep "\n" (
      map (locationConfig: ''
        location ${locationConfig.location} {
          ${optionalString (
            locationConfig.proxyPass != null && !cfg.proxyResolveWhileRunning
          ) "proxy_pass ${locationConfig.proxyPass};"}
          ${optionalString (locationConfig.proxyPass != null && cfg.proxyResolveWhileRunning) ''
            set $nix_proxy_target "${locationConfig.proxyPass}";
            proxy_pass $nix_proxy_target;
          ''}
          ${optionalString locationConfig.proxyWebsockets ''
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
          ''}
          ${optionalString (
            locationConfig.uwsgiPass != null && !cfg.uwsgiResolveWhileRunning
          ) "uwsgi_pass ${locationConfig.uwsgiPass};"}
          ${optionalString (locationConfig.uwsgiPass != null && cfg.uwsgiResolveWhileRunning) ''
            set $nix_proxy_target "${locationConfig.uwsgiPass}";
            uwsgi_pass $nix_proxy_target;
          ''}
          ${concatStringsSep "\n" (
            mapAttrsToList (name: value: ''fastcgi_param ${name} "${value}";'') (
              optionalAttrs (locationConfig.fastcgiParams != { }) (
                defaultFastcgiParams // locationConfig.fastcgiParams
              )
            )
          )}
          ${optionalString (locationConfig.index != null) "index ${locationConfig.index};"}
          ${optionalString (locationConfig.tryFiles != null) "try_files ${locationConfig.tryFiles};"}
          ${optionalString (locationConfig.root != null) "root ${locationConfig.root};"}
          ${optionalString (locationConfig.alias != null) "alias ${locationConfig.alias};"}
          ${optionalString (locationConfig.return != null) "return ${toString locationConfig.return};"}
          ${locationConfig.extraConfig}
          ${optionalString (
            locationConfig.proxyPass != null && locationConfig.recommendedProxySettings
          ) "include ${recommendedProxyConfig};"}
          ${optionalString (
            locationConfig.uwsgiPass != null && locationConfig.recommendedUwsgiSettings
          ) "include ${cfg.package}/conf/uwsgi_params;"}
          ${mkBasicAuth "sublocation" locationConfig}
        }
      '') (sortProperties (mapAttrsToList (k: v: v // { location = k; }) locations))
    );

  virtualHosts = mapAttrs (
    vhostName: vhostConfig:
    let
      serverName = if vhostConfig.serverName != null then vhostConfig.serverName else vhostName;
    in
    vhostConfig // { inherit serverName; }
  ) cfg.virtualHosts;

  oldHTTP2 = lib.versionOlder cfg.package.version "1.25.1" && cfg.package.pname != "angie";

  vhosts = concatStringsSep "\n" (
    mapAttrsToList (
      vhostName: vhost:
      let
        inherit (vhost) onlySSL;
        hasSSL = onlySSL || vhost.addSSL || vhost.forceSSL;

        mkDefaultListenVhost =
          listenLines:
          optionals (hasSSL || vhost.rejectSSL) (
            map (
              listen:
              {
                port = if (lib.hasPrefix "unix:" listen.addr) then null else cfg.defaultSSLListenPort;
                ssl = true;
              }
              // listen
            ) (filter (listen: !(listen ? ssl) || listen.ssl) listenLines)
          )
          ++ optionals (!onlySSL) (
            map (
              listen:
              {
                port = if (lib.hasPrefix "unix:" listen.addr) then null else cfg.defaultHTTPListenPort;
                ssl = false;
              }
              // listen
            ) (filter (listen: !(listen ? ssl) || !listen.ssl) listenLines)
          );

        defaultListen =
          if vhost.listen != [ ] then
            vhost.listen
          else if cfg.defaultListen != [ ] then
            mkDefaultListenVhost (
              map (listenLine: filterAttrs (_: v: (v != null)) listenLine) cfg.defaultListen
            )
          else
            let
              addrs = if vhost.listenAddresses != [ ] then vhost.listenAddresses else cfg.defaultListenAddresses;
            in
            mkDefaultListenVhost (map (addr: { inherit addr; }) addrs);

        hostListen = if vhost.forceSSL then filter (x: x.ssl) defaultListen else defaultListen;

        listenString =
          {
            addr,
            port,
            ssl,
            proxyProtocol ? false,
            extraParameters ? [ ],
            ...
          }:
          (optionalString (ssl && vhost.quic) (
            "
            listen ${addr}${optionalString (port != null) ":${toString port}"} quic "
            + optionalString vhost.default "default_server "
            + optionalString vhost.reuseport "reuseport "
            + optionalString (extraParameters != [ ]) (
              concatStringsSep " " (
                let
                  inCompatibleParameters = [
                    "accept_filter"
                    "backlog"
                    "deferred"
                    "fastopen"
                    "http2"
                    "proxy_protocol"
                    "so_keepalive"
                    "ssl"
                  ];
                  isCompatibleParameter = param: !(any (p: lib.hasPrefix p param) inCompatibleParameters);
                in
                filter isCompatibleParameter extraParameters
              )
            )
            + ";"
          ))
          + "
            listen ${addr}${optionalString (port != null) ":${toString port}"} "
          + optionalString (ssl && vhost.http2 && oldHTTP2) "http2 "
          + optionalString ssl "ssl "
          + optionalString vhost.default "default_server "
          + optionalString vhost.reuseport "reuseport "
          + optionalString proxyProtocol "proxy_protocol "
          + optionalString (extraParameters != [ ]) (concatStringsSep " " extraParameters)
          + ";";

        redirectListen = filter (x: !x.ssl) defaultListen;
      in
      ''
        ${optionalString vhost.forceSSL ''
          server {
            ${concatMapStringsSep "\n" listenString redirectListen}

            server_name ${vhost.serverName} ${concatStringsSep " " vhost.serverAliases};

            location / {
              return ${toString vhost.redirectCode} https://$host$request_uri;
            }
          }
        ''}

        server {
          ${concatMapStringsSep "\n" listenString hostListen}
          server_name ${vhost.serverName} ${concatStringsSep " " vhost.serverAliases};
          ${optionalString (hasSSL && vhost.http2 && !oldHTTP2) ''
            http2 on;
          ''}
          ${optionalString (hasSSL && vhost.quic) ''
            http3 ${if vhost.http3 then "on" else "off"};
            http3_hq ${if vhost.http3_hq then "on" else "off"};
          ''}
          ${optionalString (hasSSL && vhost.sslCertificate != null && vhost.sslCertificateKey != null) ''
            ssl_certificate ${vhost.sslCertificate};
            ssl_certificate_key ${vhost.sslCertificateKey};
          ''}
          ${optionalString (hasSSL && vhost.sslTrustedCertificate != null) ''
            ssl_trusted_certificate ${vhost.sslTrustedCertificate};
          ''}
          ${optionalString vhost.rejectSSL ''
            ssl_reject_handshake on;
          ''}
          ${optionalString (hasSSL && vhost.kTLS) ''
            ssl_conf_command Options KTLS;
          ''}

          ${mkBasicAuth vhostName vhost}

          ${optionalString (vhost.root != null) "root ${vhost.root};"}

          ${optionalString (vhost.globalRedirect != null) ''
            location / {
              return ${toString vhost.redirectCode} http${optionalString hasSSL "s"}://${vhost.globalRedirect}$request_uri;
            }
          ''}
          ${mkLocations vhost.locations}

          ${vhost.extraConfig}
        }
      ''
    ) virtualHosts
  );

  configText = ''
    ${cfg.prependConfig}

    ${optionalString (cfg.user != null)
      "user ${cfg.user}${optionalString (cfg.group != null) " ${cfg.group}"};"
    }
    pid ${cfg.pidPath};
    error_log ${cfg.logError};
    daemon off;

    ${optionalString cfg.enableQuicBPF ''
      quic_bpf on;
    ''}

    ${cfg.config}

    ${optionalString (cfg.eventsConfig != "" || cfg.config == "") ''
      events {
        ${cfg.eventsConfig}
      }
    ''}

    ${optionalString (cfg.httpConfig == "" && cfg.config == "") ''
      http {
        ${commonHttpConfig}

        ${optionalString (cfg.resolver.addresses != [ ]) ''
          resolver ${toString cfg.resolver.addresses} ${
            optionalString (cfg.resolver.valid != "") "valid=${cfg.resolver.valid}"
          } ${optionalString (!cfg.resolver.ipv4) "ipv4=off"} ${
            optionalString (!cfg.resolver.ipv6) "ipv6=off"
          };
        ''}
        ${upstreamConfig}

        ${optionalString cfg.recommendedOptimisation ''
          sendfile on;
          tcp_nopush on;
          tcp_nodelay on;
          keepalive_timeout 65;
        ''}

        ssl_protocols ${cfg.sslProtocols};
        ${optionalString (cfg.sslCiphers != null) "ssl_ciphers ${cfg.sslCiphers};"}
        ${optionalString (cfg.sslDhparam != null) "ssl_dhparam ${cfg.sslDhparam};"}

        ${optionalString cfg.recommendedTlsSettings ''
          ssl_conf_command Groups "X25519MLKEM768:X25519:P-256:P-384";
          ssl_session_timeout 1d;
          ssl_session_cache shared:SSL:10m;
          ssl_session_tickets off;
          ssl_prefer_server_ciphers off;
        ''}

        ${optionalString cfg.recommendedBrotliSettings ''
          brotli on;
          brotli_static on;
          brotli_comp_level 5;
          brotli_window 512k;
          brotli_min_length 256;
          brotli_types ${lib.concatStringsSep " " compressMimeTypes};
        ''}

        ${optionalString cfg.recommendedGzipSettings ''
          gzip on;
          gzip_static on;
          gzip_vary on;
          gzip_comp_level 5;
          gzip_min_length 256;
          gzip_proxied expired no-cache no-store private auth;
          gzip_types ${lib.concatStringsSep " " compressMimeTypes};
        ''}

        ${optionalString cfg.experimentalZstdSettings ''
          zstd on;
          zstd_comp_level 9;
          zstd_min_length 256;
          zstd_static on;
          zstd_types ${lib.concatStringsSep " " compressMimeTypes};
        ''}

        ${optionalString cfg.recommendedProxySettings ''
          proxy_redirect          off;
          proxy_connect_timeout   ${cfg.proxyTimeout};
          proxy_send_timeout      ${cfg.proxyTimeout};
          proxy_read_timeout      ${cfg.proxyTimeout};
          proxy_http_version      1.1;
          proxy_set_header        "Connection" "";
          include ${recommendedProxyConfig};
        ''}

        ${optionalString cfg.recommendedUwsgiSettings ''
          uwsgi_connect_timeout   ${cfg.uwsgiTimeout};
          uwsgi_send_timeout      ${cfg.uwsgiTimeout};
          uwsgi_read_timeout      ${cfg.uwsgiTimeout};
          uwsgi_param             HTTP_CONNECTION "";
          include ${cfg.package}/conf/uwsgi_params;
        ''}

        ${optionalString (cfg.mapHashBucketSize != null) ''
          map_hash_bucket_size ${toString cfg.mapHashBucketSize};
        ''}

        ${optionalString (cfg.mapHashMaxSize != null) ''
          map_hash_max_size ${toString cfg.mapHashMaxSize};
        ''}

        ${optionalString (cfg.serverNamesHashBucketSize != null) ''
          server_names_hash_bucket_size ${toString cfg.serverNamesHashBucketSize};
        ''}

        ${optionalString (cfg.serverNamesHashMaxSize != null) ''
          server_names_hash_max_size ${toString cfg.serverNamesHashMaxSize};
        ''}

        map $http_upgrade $connection_upgrade {
            default upgrade;
            '''      close;
        }
        client_max_body_size ${cfg.clientMaxBodySize};

        server_tokens ${if cfg.serverTokens then "on" else "off"};

        ${cfg.commonHttpConfig}

        ${proxyCachePathConfig}

        ${vhosts}

        ${cfg.appendHttpConfig}
      }
    ''}

    ${optionalString (cfg.httpConfig != "") ''
      http {
        ${commonHttpConfig}
        ${cfg.httpConfig}
      }
    ''}

    ${optionalString (cfg.streamConfig != "") ''
      stream {
        ${cfg.streamConfig}
      }
    ''}

    ${cfg.appendConfig}
  '';

  configFile =
    (if cfg.validateConfigFile then pkgs.writers.writeNginxConfig else pkgs.writeText) "nginx.conf"
      configText;
in
{
  _class = "service";

  options.nginx = {
    enable = mkEnableOption "Nginx web server";

    enableIPv6 = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to include IPv6 default listen addresses.
      '';
    };

    statusPage = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Enable status page reachable from localhost on http://127.0.0.1/nginx_status.
      '';
    };

    recommendedTlsSettings = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Enable recommended TLS settings.
      '';
    };

    recommendedOptimisation = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Enable recommended optimisation settings.
      '';
    };

    recommendedBrotliSettings = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Enable recommended brotli settings.
      '';
    };

    recommendedGzipSettings = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Enable recommended gzip settings.
      '';
    };

    experimentalZstdSettings = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Enable alpha quality zstd module with recommended settings.
      '';
    };

    recommendedProxySettings = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether to enable recommended proxy settings if a vhost does not specify the option manually.
      '';
    };

    proxyTimeout = mkOption {
      type = types.str;
      default = "60s";
      example = "20s";
      description = ''
        Change the proxy related timeouts in recommendedProxySettings.
      '';
    };

    recommendedUwsgiSettings = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether to enable recommended uwsgi settings if a vhost does not specify the option manually.
      '';
    };

    uwsgiTimeout = mkOption {
      type = types.str;
      default = "60s";
      example = "20s";
      description = ''
        Change the uwsgi related timeouts in recommendedUwsgiSettings.
      '';
    };

    defaultListen = mkOption {
      type =
        with types;
        listOf (submodule {
          options = {
            addr = mkOption {
              type = str;
              description = "IP address.";
            };
            port = mkOption {
              type = nullOr port;
              description = "Port number.";
              default = null;
            };
            ssl = mkOption {
              type = nullOr bool;
              default = null;
              description = "Enable SSL.";
            };
            proxyProtocol = mkOption {
              type = bool;
              description = "Enable PROXY protocol.";
              default = false;
            };
            extraParameters = mkOption {
              type = listOf str;
              description = "Extra parameters of this listen directive.";
              default = [ ];
              example = [
                "backlog=1024"
                "deferred"
              ];
            };
          };
        });
      default = [ ];
      example = literalExpression ''
        [
          { addr = "10.0.0.12"; proxyProtocol = true; ssl = true; }
          { addr = "0.0.0.0"; }
          { addr = "[::0]"; }
        ]
      '';
      description = ''
        If vhosts do not specify listen, use these addresses by default.
        This option takes precedence over {option}`defaultListenAddresses` and
        other listen-related defaults options.
      '';
    };

    defaultListenAddresses = mkOption {
      type = types.listOf types.str;
      default = [ "0.0.0.0" ] ++ optional cfg.enableIPv6 "[::0]";
      defaultText = literalExpression ''[ "0.0.0.0" ] ++ lib.optional config.nginx.enableIPv6 "[::0]"'';
      example = literalExpression ''[ "10.0.0.12" "[2002:a00:1::]" ]'';
      description = ''
        If vhosts do not specify listenAddresses, use these addresses by default.
        This is akin to writing `defaultListen = [ { addr = "0.0.0.0" } ]`.
      '';
    };

    defaultHTTPListenPort = mkOption {
      type = types.port;
      default = 80;
      example = 8080;
      description = ''
        If vhosts do not specify listen.port, use these ports for HTTP by default.
      '';
    };

    defaultSSLListenPort = mkOption {
      type = types.port;
      default = 443;
      example = 8443;
      description = ''
        If vhosts do not specify listen.port, use these ports for SSL by default.
      '';
    };

    defaultMimeTypes = mkOption {
      type = types.path;
      default = "${pkgs.mailcap}/etc/nginx/mime.types";
      defaultText = literalExpression "$''{pkgs.mailcap}/etc/nginx/mime.types";
      example = literalExpression "$''{pkgs.nginx}/conf/mime.types";
      description = ''
        Default MIME types for NGINX.
      '';
    };

    package = mkOption {
      default = pkgs.nginxStable;
      defaultText = literalExpression "pkgs.nginxStable";
      type = types.package;
      apply = p: p.override { modules = lib.unique (p.modules ++ cfg.additionalModules); };
      description = ''
        Nginx package to use. This defaults to the stable version.
        Supported forks include `angie`, `openresty` and `tengine`.
      '';
    };

    additionalModules = mkOption {
      default = [ ];
      type = types.listOf (types.attrsOf types.anything);
      example = literalExpression "[ pkgs.nginxModules.echo ]";
      description = ''
        Additional third-party nginx modules to install. Packaged modules are available in `pkgs.nginxModules`.
      '';
    };

    logError = mkOption {
      default = "stderr";
      type = types.str;
      description = ''
        Configures logging. See nginx docs for available log levels.
      '';
    };

    config = mkOption {
      type = types.str;
      default = "";
      description = ''
        Verbatim nginx.conf configuration. Mutually exclusive to structured config options.
      '';
    };

    prependConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Configuration lines prepended to the generated nginx configuration file.
      '';
    };

    appendConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Configuration lines appended to the generated nginx configuration file.
      '';
    };

    commonHttpConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''
        resolver 127.0.0.1 valid=5s;

        log_format myformat '$remote_addr - $remote_user [$time_local] '
                            '"$request" $status $body_bytes_sent '
                            '"$http_referer" "$http_user_agent"';
      '';
      description = ''
        Common http context definitions before they are used.
      '';
    };

    httpConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Configuration lines to be set inside the http block.
      '';
    };

    streamConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''
        server {
          listen 127.0.0.1:53 udp reuseport;
          proxy_timeout 20s;
          proxy_pass 192.168.0.1:53535;
        }
      '';
      description = ''
        Configuration lines to be set inside the stream block.
      '';
    };

    eventsConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Configuration lines to be set inside the events block.
      '';
    };

    appendHttpConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Configuration lines to be appended to the generated http block.
      '';
    };

    enableQuicBPF = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Enables routing of QUIC packets using eBPF. Requires Linux 5.7+.
      '';
    };

    user = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "User account under which nginx runs.";
    };

    group = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Group account under which nginx runs.";
    };

    pidPath = mkOption {
      type = types.str;
      default = "/tmp/nginx.pid";
      description = "Path to nginx pid file.";
    };

    serverTokens = mkOption {
      type = types.bool;
      default = false;
      description = "Show nginx version in headers and error pages.";
    };

    clientMaxBodySize = mkOption {
      type = types.str;
      default = "10m";
      description = "Set nginx global client_max_body_size.";
    };

    sslCiphers = mkOption {
      type = types.nullOr types.str;
      default = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305";
      description = "Ciphers to choose from when negotiating TLS handshakes.";
    };

    sslProtocols = mkOption {
      type = types.str;
      default = "TLSv1.2 TLSv1.3";
      example = "TLSv1 TLSv1.1 TLSv1.2 TLSv1.3";
      description = "Allowed TLS protocol versions.";
    };

    sslDhparam = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/path/to/dhparams.pem";
      description = "Path to DH parameters file.";
    };

    proxyResolveWhileRunning = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Resolves domains of proxyPass targets at runtime and not only at startup.
      '';
    };

    uwsgiResolveWhileRunning = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Resolves domains of uwsgi targets at runtime and not only at startup.
      '';
    };

    mapHashBucketSize = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = ''
        Sets the bucket size for the map variables hash tables.
      '';
    };

    mapHashMaxSize = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = ''
        Sets the maximum size of the map variables hash tables.
      '';
    };

    serverNamesHashBucketSize = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = ''
        Sets the bucket size for the server names hash tables.
      '';
    };

    serverNamesHashMaxSize = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = ''
        Sets the maximum size of the server names hash tables.
      '';
    };

    typesHashMaxSize = mkOption {
      type = types.ints.positive;
      default = if cfg.defaultMimeTypes == "${pkgs.mailcap}/etc/nginx/mime.types" then 2688 else 1024;
      defaultText = literalExpression ''if config.nginx.defaultMimeTypes == "''${pkgs.mailcap}/etc/nginx/mime.types" then 2688 else 1024'';
      description = ''
        Sets the maximum size of the types hash tables (`types_hash_max_size`).
      '';
    };

    proxyCachePath = mkOption {
      type = types.attrsOf (
        types.submodule (_: {
          options = {
            enable = mkEnableOption "this proxy cache path entry";

            keysZoneName = mkOption {
              type = types.str;
              default = "cache";
              example = "my_cache";
              description = "Set name to shared memory zone.";
            };

            keysZoneSize = mkOption {
              type = types.str;
              default = "10m";
              example = "32m";
              description = "Set size to shared memory zone.";
            };

            levels = mkOption {
              type = types.str;
              default = "1:2";
              example = "1:2:2";
              description = ''
                The levels parameter defines structure of subdirectories in cache.
              '';
            };

            useTempPath = mkOption {
              type = types.bool;
              default = false;
              example = true;
              description = ''
                Whether nginx should write cache files directly to the final path.
              '';
            };

            inactive = mkOption {
              type = types.str;
              default = "10m";
              example = "1d";
              description = ''
                Cached data that has not been accessed for the time specified by
                the inactive parameter is removed from the cache.
              '';
            };

            maxSize = mkOption {
              type = types.str;
              default = "1g";
              example = "2048m";
              description = "Set maximum cache size";
            };
          };
        })
      );
      default = { };
      description = ''
        Configure a proxy cache path entry.
      '';
    };

    resolver = mkOption {
      type = types.submodule {
        options = {
          addresses = mkOption {
            type = types.listOf types.str;
            default = [ ];
            example = literalExpression ''[ "[::1]" "127.0.0.1:5353" ]'';
            description = "List of resolvers to use";
          };
          valid = mkOption {
            type = types.str;
            default = "";
            example = "30s";
            description = ''
              By default, nginx caches answers using the TTL value of a response.
            '';
          };
          ipv4 = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Whether to look up IPv4 addresses while resolving.
            '';
          };
          ipv6 = mkOption {
            type = types.bool;
            default = cfg.enableIPv6;
            defaultText = literalExpression "config.nginx.enableIPv6";
            description = ''
              Whether to look up IPv6 addresses while resolving.
            '';
          };
        };
      };
      description = ''
        Configures name servers used to resolve names of upstream servers into addresses
      '';
      default = { };
    };

    upstreams = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            servers = mkOption {
              type = types.attrsOf (
                types.submodule {
                  freeformType = types.attrsOf (
                    types.oneOf [
                      types.bool
                      types.int
                      types.str
                    ]
                  );
                  options = {
                    backup = mkOption {
                      type = types.bool;
                      default = false;
                      description = ''
                        Marks the server as a backup server.
                      '';
                    };
                  };
                }
              );
              description = ''
                Defines the address and other parameters of the upstream servers.
              '';
              default = { };
              example = lib.literalMD "see NixOS services.nginx.upstreams";
            };
            extraConfig = mkOption {
              type = types.lines;
              default = "";
              description = ''
                These lines go to the end of the upstream verbatim.
              '';
            };
          };
        }
      );
      description = ''
        Defines a group of servers to use as proxy target.
      '';
      default = { };
    };

    virtualHosts = mkOption {
      type = types.attrsOf (
        types.submodule (vhostOptions {
          inherit config lib;
        })
      );
      default = {
        localhost = { };
      };
      example = literalExpression ''
        {
          "example.org" = {
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://localhost:3000";
            };
          };
        };
      '';
      description = "Declarative vhost config";
    };

    validateConfigFile = lib.mkEnableOption "validating configuration with pkgs.writeNginxConfig" // {
      default = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      nginx.additionalModules =
        optional cfg.recommendedBrotliSettings pkgs.nginxModules.brotli
        ++ optional cfg.experimentalZstdSettings pkgs.nginxModules.zstd;
    }

    (mkIf cfg.statusPage {
      nginx.virtualHosts.localhost = {
        serverAliases = [ "127.0.0.1" ] ++ optional cfg.enableIPv6 "[::1]";
        listenAddresses = [ "0.0.0.0" ] ++ optional cfg.enableIPv6 "[::]";
        locations."/nginx_status" = {
          extraConfig = ''
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            ${optionalString cfg.enableIPv6 "allow ::1;"}
            deny all;
          '';
        };
      };
    })

    {
      assertions =
        let
          hostOrAliasIsNull = location: location.root == null || location.alias == null;
        in
        [
          {
            assertion = all (host: all hostOrAliasIsNull (attrValues host.locations)) (attrValues virtualHosts);
            message = "Only one of nginx root or alias can be specified on a location.";
          }

          {
            assertion = all (
              host:
              with host;
              count id [
                addSSL
                onlySSL
                forceSSL
                rejectSSL
              ] <= 1
            ) (attrValues virtualHosts);
            message = ''
              Options nginx.virtualHosts.<name>.addSSL,
              nginx.virtualHosts.<name>.onlySSL,
              nginx.virtualHosts.<name>.forceSSL and
              nginx.virtualHosts.<name>.rejectSSL are mutually exclusive.
            '';
          }

          {
            assertion = all (
              host:
              let
                listenHasSSL = any (line: (line ? ssl) && line.ssl) host.listen;
                hasSSL = host.onlySSL || host.addSSL || host.forceSSL;
              in
              (!hasSSL && !host.rejectSSL && !listenHasSSL)
              || (host.sslCertificate != null && host.sslCertificateKey != null)
            ) (attrValues virtualHosts);
            message = ''
              SSL-enabled virtual hosts must set both
              nginx.virtualHosts.<name>.sslCertificate and
              nginx.virtualHosts.<name>.sslCertificateKey.
            '';
          }

          {
            assertion = all (
              host:
              all (location: !(location.proxyPass != null && location.uwsgiPass != null)) (
                attrValues host.locations
              )
            ) (attrValues virtualHosts);
            message = ''
              Options nginx.virtualHosts.<name>.proxyPass and
              nginx.virtualHosts.<name>.uwsgiPass are mutually exclusive.
            '';
          }

          {
            assertion = cfg.resolver.ipv4 || cfg.resolver.ipv6;
            message = ''
              At least one of nginx.resolver.ipv4 and nginx.resolver.ipv6 must be true.
            '';
          }
        ];

      configData."nginx.conf".source = configFile;

      process.argv = [
        (lib.getExe cfg.package)
        "-c"
        config.configData."nginx.conf".path
      ];
    }
  ]);
}
