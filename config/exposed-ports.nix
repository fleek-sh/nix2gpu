{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.exposedPorts = mkOption {
    description = ''
      exposed ports for your container.
    '';
    type = types.attrsOf types.anything;
    default = {
      "22/tcp" = { };
    };
  };
}
