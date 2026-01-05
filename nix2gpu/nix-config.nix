{ lib, ... }:
let
  inherit (lib)
    types
    mkOption
    literalExpression
    literalMD
    ;

  defaultContents = builtins.readFile ./container/config/nix.conf;
in
{
  _class = "nix2gpu";

  options.nixConfig = mkOption {
    description = ''
      The content of the [`nix.conf`](https://nix.dev/manual/nix/2.31/command-ref/conf-file.html) file to be used inside the container.

      This option allows you to provide a custom `nix.conf` configuration for
      the Nix daemon running inside the container. This can be used to
      configure things like custom binary caches, experimental features, or
      other Nix-related settings.

      By default, a standard `nix.conf` is provided which is suitable for most
      use cases.
    '';
    example = literalExpression ''
      nixConfig = '''
        experimental-features = nix-command flakes
        substituters = https://cache.nixos.org/ https://my-cache.example.org
        trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= my-cache.example.org-1:abcdef...
      ''';
    '';
    type = types.str;
    default = defaultContents;
    defaultText = literalMD ''
      ```
      ${defaultContents}
      ```
    '';
  };
}
