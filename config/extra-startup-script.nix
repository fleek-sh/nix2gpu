{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.extraStartupScript = mkOption {
    description = ''
      A string of shell commands to be executed at the end of the container's startup script.

      This option provides a way to run custom commands every time the
      container starts. The contents of this option will be appended to the
      main startup script, after the default startup tasks have been completed.

      This is useful for tasks such as starting services, running background
      processes, or printing diagnostic information.

      **Example:**

      ```nix
      extraStartupScript = '''
        echo "Launching custom startup script process..."
        # Start a background service
        my-service &
      ''';
      ```
    '';
    type = types.str;
    default = "";
  };
}
