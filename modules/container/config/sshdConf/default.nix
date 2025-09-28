{ config, flake-parts-lib, ... }:
{
  options.nix2vast.sshdConfig = flake-parts-lib.mkPerSystemOption (
    { pkgs, ... }:
    let
      sshdConf = pkgs.replaceVars ./sshd_config { inherit (pkgs) openssh; };
    in
    {
      description = ''
        a replacement sshd configuration to use.
      '';
      type = config.types.textFilePackage;
      default = sshdConf;
    }
  );
}
