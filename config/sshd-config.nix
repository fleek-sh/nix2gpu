{ config, lib, ... }:
let
  inherit (lib) types mkOption;
  inherit (config) pkgs;

  sshdConf = pkgs.replaceVars ../modules/container/config/sshd_config { inherit (pkgs) openssh; };
in
{
  options.sshdConfig = mkOption {
    description = ''
      a replacement sshd.conf to use.
    '';
    type = types.str;
    default = builtins.readFile sshdConf;
  };
}
