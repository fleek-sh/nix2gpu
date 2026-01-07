{ pkgs, ... }:
{ lib, config, ... }:
let
  inherit (lib) mkOption mkPackageOption types;

  cfg = config.comfyui;

  comfyuiPackage = cfg.package.override {
    withModels = cfg.models;
    withCustomNodes = cfg.customNodes;
  };
in
{
  _class = "service";

  options.comfyui = {
    package = mkPackageOption pkgs "comfyui" { };

    dataDir = mkOption {
      type = types.str;
      default = "/workspace";
      example = "/workspace/comfyui";
      description = ''
        Directory used for ComfyUI outputs and database storage.
      '';
    };

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
      default = "${cfg.dataDir}/comfyui.db";
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
        runtimeEnv = cfg.environmentVariables;
        text = ''
          ${lib.getExe comfyuiPackage} \
            --listen ${cfg.listen} \
            --port ${toString cfg.port} \
            --output-directory ${cfg.dataDir} \
            --database-url ${cfg.databasePath} \
            ${lib.concatStringsSep " " cfg.extraFlags} \
            "$@"
        '';
      };
    in
    {
      process.argv = [ (lib.getExe wrapper) ];
    };
}
