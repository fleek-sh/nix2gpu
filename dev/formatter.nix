{ inputs, ... }:
let
  indentWidth = 2;
  lineLength = 100;
in
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem.treefmt = {
    projectRootFile = "flake.nix";
    programs = {
      keep-sorted.enable = true;

      nixfmt = {
        enable = true;
        strict = true;
        width = lineLength;
      };

      shfmt = {
        enable = true;
        indent_size = indentWidth;
      };
      shellcheck.enable = true;

      statix.enable = true;
      deadnix.enable = true;

      yamlfmt.enable = true;
      mdformat.enable = true;
    };
  };
}
