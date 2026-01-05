{ lib, pkgs, ... }:
let
  inherit (lib)
    types
    mkOption
    literalExpression
    literalMD
    ;

  sshdConf = pkgs.replaceVars ./container/config/sshd_config { inherit (pkgs) openssh; };
in
{
  _class = "nix2gpu";

  options.sshdConfig = mkOption {
    description = ''
      The content of the `sshd_config` file to be used inside the container.

      This option allows you to provide a custom configuration for the OpenSSH
      daemon (`sshd`) running inside the container. This can be used to
      customize security settings, authentication methods, and other SSH-related
      options.

      By default, a standard `sshd_config` is provided that is suitable for most
      use cases, with password authentication disabled in favor of public key
      authentication.
    '';
    example = literalExpression ''
      sshdConfig = builtins.readFile ./my-sshd-config;
    '';
    type = types.str;
    default = builtins.readFile sshdConf;
    defaultText = literalMD ''
      nix2gpu generated sshd config
    '';
  };
}
