{ lib, ... }:
let
  inherit (lib) types mkOption literalExpression;
in
{
  options.exposedPorts = mkOption {
    description = ''
      A set of ports to expose from the container.

      This option allows you to specify which network ports should be
      exposed by the container. The keys are the port and protocol
      (e.g., "80/tcp"), and the values are empty attribute sets.

      By default, port 22 is exposed for SSH access.

      > This is a direct mapping to the `ExposedPorts` attribute of the [oci container
      > spec](https://github.com/opencontainers/image-spec/blob/8b9d41f48198a7d6d0a5c1a12dc2d1f7f47fc97f/specs-go/v1/config.go#L23). 
    '';
    example = literalExpression ''
      exposedPorts = {
        "8080/tcp" = {};
        "443/tcp" = {};
      };
    '';
    type = types.attrsOf types.anything;
    default = {
      "22/tcp" = { };
    };
  };
}
