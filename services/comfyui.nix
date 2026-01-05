{ pkgs, ... }:
{ lib, config, ... }:
let
  inherit (lib) mkOption mkPackageOption types;

  comfyuiPackage = config.package.override {
    withModels = config.models;
    withCustomNodes = config.customNodes;
  };
in
{
  _class = "service";

  options.comfyui = {
    package = mkPackageOption pkgs "comfyui" { };

    listen = mkOption {
      type = types.nullOr types.str;
      default = "127.0.0.1";
      description = ''
        The IP interface to bind to.
      '';
      example = "127.0.0.1";
    };

    port = mkOption {
      type = types.port;
      default = 8188;
      description = ''
        The TCP port to accept connections.
      '';
    };

    databasePath = mkOption {
      type = types.str;
      default = "${config.dataDir}/comfyui.db";
      example = "/home/my-user/comfyui/comfyui.db";
      description = ''
        SQL database URL. Passed as --database-url cli flag to comfyui. If it does not start with sqlite:/// it will be prepended automatically.
      '';
      apply = x: if (lib.hasPrefix "sqlite:///" x) then x else "sqlite:///${x}";
    };

    extraFlags = mkOption {
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

    models = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      defaultText = [ ];
      example = [ ];
      description = ''
        A list of models to fetch and supply to comfyui
      '';
    };

    customNodes = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      defaultText = [ ];
      example = [ ];
      description = ''
        A list of custom nodes to fetch and supply to comfyui in its custom_nodes folder
      '';
    };

    environmentVariables = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        HIP_VISIBLE_DEVICES = "0,1";
      };
      description = ''
        Set arbitrary environment variables for the comfyui service.
      '';
    };
  };

  config =
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
      process.argv = [ wrapper ];
    };
}
