{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];
  perSystem =
    let
      indentWidth = 2;
      lineLength = 100;
    in
    { pkgs, ... }:
    {
      treefmt = {
        # n.b. custom biome formatter that uses `biome.json`
        settings.formatter.biome-custom = {
          command = "${pkgs.biome}/bin/biome";
          options = [
            "format"
            "--write"
          ];
          includes = [
            "*.js"
            "*.mjs"
            "*.jsx"
            "*.ts"
            "*.tsx"
            "*.json"
            "*.jsonc"
            "*.css"
          ];
        };

        programs.ruff-format.enable = true;
        programs.deadnix.enable = true;
        programs.dos2unix.enable = true;
        programs.just.enable = true;
        programs.keep-sorted.enable = true;
        programs.nixfmt.enable = true;
        programs.nixfmt.strict = true;
        programs.nixfmt.width = lineLength;
        programs.shfmt.enable = true;
        programs.shfmt.indent_size = indentWidth;
        programs.statix.enable = true;
        programs.taplo.enable = true;
        programs.yamlfmt.enable = true;
      };
    };
}
