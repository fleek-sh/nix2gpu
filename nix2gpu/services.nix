{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) types mkOption;
in
{
  _class = "nix2gpu";

  options.services = mkOption {
    description = ''
      TODO
    '';
    type = types.lazyAttrsOf types.deferredModule;
    default = { };
    visible = "shallow";
  };
}
