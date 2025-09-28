{ inputs, lib, ... }:
let
  nixFiles = (inputs.import-tree.withLib lib).leafs ../.;
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks.allFilesHaveLowerCaseNames = pkgs.runCommandLocal "lower-case-name-check" { } ''
        for file in ${lib.concatStringsSep " " nixFiles};
        do
          if basename "$file" | grep -q '[A-Z]'; then
            printf '\033[31mError:\033[0m %s.\n' 'This repository expects all nix file names to be formatted-in-kebab-case' >&2
            printf '\033[31mFailing File:\033[0m `%s`.\n' "$file" >&2
            exit 1
          fi
        done

        mkdir -p $out
      '';
    };
}
