{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.services = mkOption {
    description = ''
      the [`services-flake`](https://github.com/juspay/services-flake)
      configuration to use inside your `nix2vast` container.

      when your container is launched it boots into a
      [process-compose](https://github.com/F1bonacc1/process-compose]
      interface running all services specificed. 

      this can be useful for running your own web servers or things
      like nginx.
    '';
    type = types.lazyAttrsOf types.raw;
    default = { };
  };
}
