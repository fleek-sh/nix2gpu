{ lib, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.docs =
        let
          moduleEval = lib.evalModules {
            modules = [ self.modules.nix2gpu.default ];
            class = "nix2gpu";
            specialArgs = { inherit pkgs; };
          };

          moduleOptsDoc = pkgs.nixosOptionsDoc { inherit (moduleEval) options; };
        in
        pkgs.stdenvNoCC.mkDerivation {
          name = "options-doc-html";
          src = ../.;

          nativeBuildInputs = with pkgs; [
            mdbook
            nixdoc
          ];

          dontBuild = true;
          installPhase = ''
            mkdir -p "$out/share/nix2gpu/docs"

            ln -sf "${moduleOptsDoc.optionsCommonMark}" docs/options.md

            mdbook build --dest-dir "$out/share/nix2gpu/docs"
          '';
        };
    };
}
