{ config, ... }:
{
  options.nix2vast.perSystem =
    { pkgs, ... }:
    let
      sshdConf = pkgs.replaceVars ./sshd_config {
        openssh = pkgs.openssh;
      };
    in
    {
      sshdConfig = pkgs.mkOption {
        description = ''
          a replacement sshd configuration to use.
        '';
        type = config.types.textFilePackage;
        default = sshdConf;
      };
    };
}
