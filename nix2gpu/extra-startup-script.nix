{ lib, ... }:
let
  inherit (lib) mkOption literalExpression mkOptionType;
in
{
  _class = "nix2gpu";

  options.extraStartupScript = mkOption {
    description = ''
      A string of shell commands to be executed at the end of the container's startup script.

      This option provides a way to run custom commands every time the
      container starts. The contents of this option will be appended to the
      main startup script, after the default startup tasks have been completed.

      This is useful for tasks such as starting services, running background
      processes, or printing diagnostic information.
    '';
    example = literalExpression ''
      extraStartupScript = '''
        echo "Hello world"
      ''';
    '';
    type = mkOptionType {
      name = "concatable-str";
      description = "string (concatenated when merged)";
      check = lib.isString;
      merge = _loc: defs: lib.concatStrings (map (d: d.value) defs);
    };
    default = "";
  };
}
