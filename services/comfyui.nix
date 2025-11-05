{
  lib,
  name,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) types;

  comfyuiPackage = config.package.override {
    withModels = config.models;
    withCustomNodes = config.customNodes;
  };
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

    databasePath = lib.mkOption {
      type = types.str;
      default = "${config.dataDir}/comfyui.db";
      example = "/home/my-user/comfyui/comfyui.db";
      description = ''
        SQL database URL. Passed as --database-url cli flag to comfyui. If it does not start with sqlite:/// it will be prepended automatically.
      '';
      apply = x: if (lib.hasPrefix "sqlite:///" x) then x else "sqlite:///${x}";
    };

    extraFlags = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "--fast"
        "--deterministic"
      ];
      description = ''
        A list of extra string arguments to pass to comfyui
      '';
    };

    models = lib.mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      defaultText = [ ];
      example = [ ];
      description = ''
        A list of models to fetch and supply to comfyui
      '';
    };

    customNodes = lib.mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      defaultText = [ ];
      example = [ ];
      description = ''
        A list of custom nodes to fetch and supply to comfyui in its custom_nodes folder
      '';
    };

    environmentVariables = lib.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        HIP_VISIBLE_DEVICES = "0,1";
      };
      description = ''
        Set arbitrary environment variables for the comfyui service.

        Be aware that these are only seen by the comfyui server (systemd service),
        not normal invocations like `comfyui run`.
        Since `comfyui run` is mostly a shell around the comfyui server, this is usually sufficient.
      '';
    };
  };

  config.outputs.settings.processes."${name}" =
    let
      wrapper = pkgs.writeShellApplication {
        name = "comfyui";
        runtimeEnv = config.environmentVariables;
        text = ''
          ${lib.getExe comfyuiPackage} \
            --listen ${config.listen} \
            --port ${toString config.port} \
            --output-directory ${config.dataDir} \
            --database-url ${config.databasePath} \
            ${lib.concatStringsSep " " config.extraFlags} \
            "$@"
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
