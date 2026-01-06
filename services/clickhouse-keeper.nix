{ pkgs, ... }:
{ lib, config, ... }:
let
  inherit (lib) mkOption mkPackageOption types;

  cfg = config.clickhouse-keeper;

  defaultConfig = ''
    <clickhouse>
      <logger>
        <level>${cfg.logLevel}</level>
        <console>1</console>
      </logger>

      <listen_host>${cfg.listenHost}</listen_host>

      <keeper_server>
        <server_id>${toString cfg.serverId}</server_id>
        <tcp_port>${toString cfg.tcpPort}</tcp_port>
        <log_storage_path>${cfg.dataDir}/coordination/log</log_storage_path>
        <snapshot_storage_path>${cfg.dataDir}/coordination/snapshots</snapshot_storage_path>

        <coordination_settings>
          <operation_timeout_ms>${toString cfg.operationTimeoutMs}</operation_timeout_ms>
          <session_timeout_ms>${toString cfg.sessionTimeoutMs}</session_timeout_ms>
          <raft_logs_level>${cfg.raftLogsLevel}</raft_logs_level>
        </coordination_settings>

        <raft_configuration>
          ${lib.concatMapStringsSep "\n" (server: ''
            <server>
              <id>${toString server.id}</id>
              <hostname>${server.host}</hostname>
              <port>${toString server.port}</port>
            </server>
          '') cfg.raftServers}
        </raft_configuration>
      </keeper_server>

      ${cfg.extraConfig}
    </clickhouse>
  '';
in
{
  _class = "service";

  options.clickhouse-keeper = {
    package = mkPackageOption pkgs "clickhouse" { example = "pkgs.clickhouse-lts"; };

    dataDir = mkOption {
      type = types.str;
      default = "/workspace/clickhouse-keeper";
      example = "/workspace/clickhouse-keeper";
      description = ''
        Directory used for ClickHouse Keeper state.
      '';
    };

    listenHost = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = ''
        Address to bind for keeper TCP connections.
      '';
    };

    tcpPort = mkOption {
      type = types.port;
      default = 9181;
      description = ''
        TCP port for keeper client connections.
      '';
    };

    serverId = mkOption {
      type = types.ints.positive;
      default = 1;
      description = ''
        Keeper server ID used in the raft configuration.
      '';
    };

    raftPort = mkOption {
      type = types.port;
      default = 9444;
      description = ''
        TCP port used for raft communication.
      '';
    };

    raftServers = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            id = mkOption {
              type = types.ints.positive;
              description = "Raft server ID.";
            };
            host = mkOption {
              type = types.str;
              description = "Raft server hostname.";
            };
            port = mkOption {
              type = types.port;
              description = "Raft server port.";
            };
          };
        }
      );
      default = [
        {
          id = cfg.serverId;
          host = cfg.listenHost;
          port = cfg.raftPort;
        }
      ];
      description = ''
        Raft configuration for keeper peers.
      '';
    };

    operationTimeoutMs = mkOption {
      type = types.ints.positive;
      default = 10000;
      description = ''
        Keeper operation timeout in milliseconds.
      '';
    };

    sessionTimeoutMs = mkOption {
      type = types.ints.positive;
      default = 30000;
      description = ''
        Keeper session timeout in milliseconds.
      '';
    };

    raftLogsLevel = mkOption {
      type = types.str;
      default = "information";
      description = ''
        Raft logs level.
      '';
    };

    logLevel = mkOption {
      type = types.str;
      default = "information";
      description = ''
        Keeper logger level.
      '';
    };

    configText = mkOption {
      type = types.nullOr types.lines;
      default = null;
      description = ''
        Full keeper config XML. When set, it replaces the generated configuration.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional XML appended inside the <clickhouse> root element.
      '';
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Extra arguments to pass to clickhouse-keeper.
      '';
    };

    environmentVariables = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Set arbitrary environment variables for the clickhouse-keeper service.
      '';
    };
  };

  config =
    let
      configFile = if cfg.configText != null then cfg.configText else defaultConfig;
      wrapper = pkgs.writeShellApplication {
        name = "clickhouse-keeper";
        runtimeEnv = cfg.environmentVariables;
        text = ''
          exec ${lib.getExe' cfg.package "clickhouse-keeper"} \
            --config ${config.configData."keeper.xml".path} \
            ${lib.concatStringsSep " " cfg.extraArgs}
        '';
      };
    in
    {
      configData."keeper.xml".text = configFile;
      process.argv = [ wrapper ];
    };
}
