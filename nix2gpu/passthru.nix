{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.passthru = mkOption {
    description = ''
      [`passthru`](https://ryantm.github.io/nixpkgs/stdenv/stdenv/#var-stdenv-passthru) attributes to
      include in the output of generated `nix2gpu` containers
    '';
    example = lib.literalExpression ''
      {
        passthru = {
          doXYZ = pkgs.writeShellApplication {
            name = "xyz-doer";
            text = '''
              xyz
            ''';
          };
        };
      }
    '';
    type = types.lazyAttrsOf types.raw;
    default = { };
  };
}
