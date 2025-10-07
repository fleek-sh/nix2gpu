{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.workingDir = mkOption {
    description = ''
      The working directory for the container.

      This option specifies the directory that will be used as the current
      working directory when the container starts. It is the directory where
      commands will be executed by default.

      The default value is "/root". You may want to change this to a
      more appropriate directory for your application, such as `/app` or
      `/srv`.

      **Example:**

      To set the working directory to `/app`:

      ```nix
      workingDir = "/app";
      ```
    '';
    type = types.str;
    default = "/root";
  };
}
