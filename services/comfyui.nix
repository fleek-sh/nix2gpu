{
  lib,
  name,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) types;
in
{
  options = {
    package = lib.mkPackageOption pkgs "comfyui" { };

    listen = lib.mkOption {
      type = types.nullOr types.str;
      default = "127.0.0.1";
      description = ''
        The IP interface to bind to.
      '';
      example = "127.0.0.1";
    };

    port = lib.mkOption {
      type = types.port;
      default = 8188;
      description = ''
        The TCP port to accept connections.
      '';
    };
  };

  config.outputs.settings.processes."${name}" =
    let
      wrapper = pkgs.writeShellApplication {
        name = "comfyui";
        text = ''
          ${lib.getExe config.package} \
            --listen ${config.listen} \
            --port ${toString config.port} \
            --output-directory ${config.dataDir}
        '';
      };
    in
    {
      command = lib.getExe wrapper;
      availability = {
        restart = "on_failure";
        max_restarts = 5;
      };
      readiness_probe = {
        http_get = {
          inherit (config) port;
          host = config.listen;
        };
        initial_delay_seconds = 2;
        period_seconds = 10;
        timeout_seconds = 4;
        success_threshold = 1;
        failure_threshold = 5;
      };
    };
}
