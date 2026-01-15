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

  wrapper = pkgs.writeShellApplication {
    name = "tailscale-service";
    runtimeInputs = [ pkgs.gum ];
    text = ''
      if [[ -f "${cfg.authKey}" ]]; then
        export TAILSCALE_AUTHKEY="${cfg.authKey}"
      else
        ${lib.getExe pkgs.gum} style --foreground 214 --bold "[nix2gpu] warning: Path \"${cfg.authKey}\" does not exist (set via \"cfg.authKey\"), TAILSCALE_AUTHKEY will not be set."
      fi

      mkdir -p /var/lib/tailscale


      gum log --level debug "Starting Tailscale daemon..."
      tailscaled --tun=userspace-networking --socket=/var/run/tailscale/tailscaled.sock 2>&1 &

      TAILSCALED_PID=$!

      if [ -n "''${TAILSCALE_AUTHKEY:-}" ]; then
        gum log --level debug "Authenticating tailscale..."
        sleep 3
        tailscale up --authkey="$TAILSCALE_AUTHKEY" --ssh &
      else
        gum log --level debug "Tailscale running (no authkey provided)"
      fi

      wait "$TAILSCALED_PID"
    '';
  };
in
{
  _class = "nix2gpu";

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
    services.tailscale = {
      process.argv = [ (lib.getExe wrapper) ];
    };
  };
}
