{ lib, ... }:
let
  inherit (lib) types mkOption literalExpression;
in
{
  options.extraCopyToRoot = mkOption {
    description = ''
      A list of extra packages to be copied to the root of the container.

      This option allows you to add more packages to the `copyToRoot` option
      without overriding the default set of essential packages. The packages
      listed here will be appended to the main `copyToRoot` list.

      This is the recommended way to add your own packages to the container's
      root directory.
    '';
    example = literalExpression ''
      extraCopyToRoot = with pkgs; [
        btop
        neovim
      ];
    '';
    type = types.listOf types.package;
    default = [ ];
  };
}
