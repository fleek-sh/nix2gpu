{ self, ... }:
{
  perSystem =
    { inputs', pkgs, ... }:
    {
      packages.docs =
        let
          moduleOpts = pkgs.lib.evalModules { modules = [ self.modules.nix2gpu.default ]; };

          moduleOptsDoc = pkgs.nixosOptionsDoc { options = moduleOpts; };
        in
        pkgs.runCommandLocal "nix2gpu-docs" { nativeBuildInputs = [ inputs'.ndg.packages.default ]; } ''
          mkdir -p "$out/share/nix2gpu/docs"

          ndg html \
            --input-dir "${self}/docs" \
            --output-dir "$out/share/nix2gpu/docs" \
            --title "`nix2gpu` Documentation" \
            --module-options ${moduleOptsDoc.optionsJSON}/share/doc/nixos/options.json \
            --jobs $NIX_BUILD_CORES \
            --generate-search \
            --highlight-code
        '';
    };
}
