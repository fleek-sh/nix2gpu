{ inputs, lib, flake-parts-lib, ... }:
let
  inherit (lib) types mkOption;
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  imports = [ inputs.flake-parts-website.flakeModules.empty-site ];

  options.perSystem = mkPerSystemOption ({pkgs, ...}:{
    options.pythonWithMkdocs = mkOption {
      description = ''
        python instance with suitable mkdocs plugins included
      '';
      type = types.package;
      default = pkgs.python3.withPackages(ps: with ps; [
        mkdocs
        mkdocs-material
      ]);
      internal = true;
    };
  });

  config.perSystem = {pkgs, config, self', ...}:{
    render.inputs.self = {
      baseUrl = "https://github.com/fleek-platform/nix2vast/blob/main";
      title = "nix2vast";
      intro = ''
        nix2vast documentation
      '';
      separateEval = true;
      extraInputs = inputs;
    };

    packages.docs = pkgs.stdenvNoCC.mkDerivation {
      name = "nix2vast-docs";

      src = ../.;

      nativeBuildInputs = [
        config.pythonWithMkdocs
        pkgs.mkdocs
      ];

      preBuild = ''
        ln -sf "${self'.packages.generated-docs-self}" ./docs/options.md
      '';

      buildPhase = ''
        mkdocs build
      '';

      installPhase = ''
        mkdir -p "$out/share/nix2vast/site"

        cp -r site/. "$out/share/nix2vast/site"
      '';
    };
  };
}
