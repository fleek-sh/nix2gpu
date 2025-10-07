{ config, lib, ... }:
let
  inherit (lib) types mkOption;
  inherit (config) pkgs;

  sshdConf = pkgs.replaceVars ../modules/container/config/sshd_config { inherit (pkgs) openssh; };
in
{
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

      **Example:**

      To allow password authentication (not recommended for production):

      ```nix
      sshdConfig = builtins.readFile ./my-sshd-config;
      ```

      Where `my-sshd-config` contains:

      ```
      # ... other sshd_config options
      PasswordAuthentication yes
      # ... other sshd_config options
      ```
    '';
    type = types.str;
    default = builtins.readFile sshdConf;
  };
}
