{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkOption literalExpression;
in
{
  _class = "nix2gpu";

  options.env = mkOption {
    description = ''
      A list of environment variables to set inside the container.

      This option allows you to define the environment variables that will be
      available within the container.

      The default value provides a comprehensive set of environment variables
      for a typical development environment, including paths for Nix, CUDA,
      and other essential tools.

      If you want to add extra environment variables without replacing the
      default set, use the `extraEnv` option instead.

      > This is a direct mapping to the `Env` attribute of the [oci container
      > spec](https://github.com/opencontainers/image-spec/blob/8b9d41f48198a7d6d0a5c1a12dc2d1f7f47fc97f/specs-go/v1/config.go#L23). 
    '';
    example = literalExpression ''
      env = {
        MY_CUSTOM_VARIABLE = "hello";
        ANOTHER_VARIABLE = "world";
      };
    '';
    type = types.attrsOf types.str;
    default = {
      CURL_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
      HOME = "/root";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      LD_LIBRARY_PATH = "/lib/x86_64-linux-gnu:/usr/lib64:/usr/lib";
      LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
      NIXPKGS_ALLOW_UNFREE = "1";
      NIX_PATH = "nixpkgs=/nix/var/nix/profiles/per-user/root/channels";
      NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      PATH = "/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
      SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      TERM = "xterm-256color";
      USER = "root";
    };
    defaultText = literalExpression ''
      CURL_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
      HOME = "/root";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      LD_LIBRARY_PATH = "/lib/x86_64-linux-gnu:/usr/lib64:/usr/lib";
      LOCALE_ARCHIVE = "glibc/lib/locale/locale-archive";
      NIXPKGS_ALLOW_UNFREE = "1";
      NIX_PATH = "nixpkgs=/nix/var/nix/profiles/per-user/root/channels";
      NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      PATH = "/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
      SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      TERM = "xterm-256color";
      USER = "root";
    '';
  };

  config.nimiSettings.container.imageConfig.Env =
    let
      translateToGoEnvString =
        var: value:

        assert lib.assertMsg (lib.toUpper var == var) ''
          `nix2gpu` env var names should be uppercase 
          in order to be properly recognized.

          The failing attribute name is `${var}`.
        '';

        "${var}=${value}";

      totalEnv = config.env // config.extraEnv;
    in
    lib.mapAttrsToList translateToGoEnvString totalEnv;
}
