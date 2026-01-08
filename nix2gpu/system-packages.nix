{ lib, config, ... }:
let
  inherit (lib) types mkOption literalExpression;
in
{
  _class = "nix2gpu";

  options.systemPackages = mkOption {
    description = ''
      A list of system packages to be copied into the container.

      This option allows you to specify a list of Nix packages that will be
      added to the container.
    '';
    example = literalExpression ''
      systemPackages = with pkgs; [
        coreutils
        git
      ];
    '';
    type = types.listOf types.package;
    default = [ ];
  };

  config = {
    extraEnv.PATH = lib.makeBinPath config.systemPackages;
    nimiSettings.container.initializeNixDatabase = true;
  };
}
