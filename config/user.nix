{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.user = mkOption {
    description = ''
      The default user for the container.

      This option specifies the username of the user that will be used by
      default when running commands or starting services in the container.

      The default value is "root". While this is convenient for development,
      it is strongly recommended to create and use a non-root user for
      production environments to improve security. You can create users
      and groups using the `users` and `groups` options in your `home-manager`
      configuration.

      **Example:**

      To set the default user to `appuser`:

      ```nix
      user = "appuser";
      ```
    '';
    type = types.str;
    default = "root";
  };
}
