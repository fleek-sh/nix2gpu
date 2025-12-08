{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    types
    mkEnableOption
    mkOption
    literalExpression
    literalMD
    mkIf
    ;

  cfg = config.tailscale;

  tailscaleType = types.submodule {
    options = {
      enable = mkEnableOption "enable the tailscale daemon";

      authKey = mkOption {
        description = ''
          Runtime path to valid tailscale auth key
        '';
        example = literalMD ''
          `/etc/default/tailscaled`
        '';
        type = types.str;
        default = "";
      };
    };
  };
in
{
  options.tailscale = mkOption {
    description = ''
      The tailscale configuration to use for your `nix2gpu` container.

      Configure the tailscale daemon to run on your `nix2gpu` instance,
      giving your instances easy and secure connectivity.
    '';
    example = literalExpression ''
      tailscale = {
        enable = true;
      };
    '';
    type = tailscaleType;
    default = { };
  };

  config = mkIf cfg.enable {
    systemPackages = with pkgs; [ tailscale ];

    extraStartupScript = ''
      if [[ -f "${cfg.authKey}" ]]; then
        export TAILSCALE_AUTHKEY="${cfg.authKey}"
      else
        printf '\033[33mWarning:\033[0m %s.\n' 'Path "${cfg.authKey}" does not exist (set via "cfg.authKey"), TAILSCALE_AUTHKEY will not be set'
      fi

      mkdir -p /var/lib/tailscale

      echo "[nix2gpu] Starting Tailscale daemon..."
      tailscaled --tun=userspace-networking --socket=/var/run/tailscale/tailscaled.sock 2>&1 &

      if [ -n "''${TAILSCALE_AUTHKEY:-}" ]; then
        echo "[nix2gpu] authenticating tailscale..."
        sleep 3
        tailscale up --authkey="$TAILSCALE_AUTHKEY" --ssh &
      else
        echo "[nix2gpu] Tailscale running (no authkey provided)"
      fi
    '';
  };
}
