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
    mkIf
    ;

  cfg = config.age;

  tailscaleType = types.submodule { enable = mkEnableOption "enable the tailscale daemon"; };
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
    extraCopyToRoot = with pkgs; [ tailscale ];

    extraStartupScript = ''
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
