{ inputs, lib, ... }:
let
  nixFiles = (inputs.import-tree.withLib lib).leafs ../.;
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks.all-files-have-lower-case-names =
        pkgs.runCommandLocal "lower-case-name-check" { nativeBuildInputs = [ pkgs.gum ]; }
          ''
            for file in ${lib.concatStringsSep " " nixFiles};
            do
              if basename "$file" | grep -q '[A-Z]'; then
                gum log \
                  --level error \
                  "This repository expects all nix file names to be formatted-in-kebab-case."

                gum log \
                  --level error \
                  "Failing File: $file."

                exit 1
              fi
            done

            mkdir -p $out
          '';
    };
}
