{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.types = lib.mkOption {
    description = ''
      nix2vast's custom types for use in describing it's config.
    '';
    type = types.attrsOf types.optionType;
  };

  config.types = {
    cudaPackageSet = types.package // {
      check = x: lib.isDerivation x && lib.hasAttr "cudatoolkit" x;
    };
    textFilePackage = types.package // {
      check = x: lib.isDerivation x && lib.hasAttr "text" x;
    };
    userDef = types.submodule {
      options.uid = mkOption {
        type = types.int;
        description = "User id";
      };
      options.gid = mkOption {
        type = types.int;
        description = "Group id";
      };
      options.shell = mkOption {
        type = types.str;
        description = "Login shell path";
      };
      options.home = mkOption {
        type = types.str;
        description = "Home directory";
      };
      options.groups = mkOption {
        type = types.listOf types.str;
        description = "Supplementary groups";
      };
      options.description = mkOption {
        type = types.str;
        description = "User description";
      };
    };
    groupDef = types.submodule {
      options.gid = mkOption {
        type = types.int;
        description = "Group id";
      };
    };
  };
}
