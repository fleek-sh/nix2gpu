{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.extraLabels = mkOption {
    description = ''
      A set of extra labels to apply to the container.

      This option allows you to add custom metadata to the container in the
      form of labels. These labels can be used for organizing and filtering
      containers, or for storing information about the container's contents
      or purpose.

      The labels defined here will be merged with the default `labels` set.

      This is the recommended way to add more labels to your project 
      rather than overriding labels.

      **Example:**

      ```nix
      extraLabels = {
        "com.example.vendor" = "My Company";
        "com.example.project" = "My Project";
      };
      ```
    '';
    type = types.attrsOf types.str;
    default = { };
  };
}
