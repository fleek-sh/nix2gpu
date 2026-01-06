{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) types mkOption;

  servicesModule =
    lib.modules.importApply "${inputs.nixpkgs}/nixos/modules/system/service/portable/service.nix"
      { inherit pkgs; };
in
{
  _class = "nix2gpu";

  options.services = mkOption {
    description = ''
      TODO
    '';
    type = types.lazyAttrsOf (
      types.submoduleWith {
        class = "service";
        modules = [ servicesModule ];
      }
    );
    default = { };
  };
}
