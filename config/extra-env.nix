{ lib, ... }:
let
  inherit (lib) types mkOption literalExpression;
in
{
  options.extraEnv = mkOption {
    description = ''
      A list of extra environment variables to set inside the container.

      This option allows you to add more environment variables to the `env`
      option without overriding the default set. The variables listed here
      will be appended to the main `env` list.

      This is the recommended way to add your own custom environment variables.
    '';
    example = literalExpression ''
      extraEnv = {
        DATABASE_URL = "postgres://user:password@host:port/db";
        NIXPKGS_ALLOW_UNFREE = "1";
      };
    '';
    type = types.attrsOf types.str;
    default = { };
  };
}
