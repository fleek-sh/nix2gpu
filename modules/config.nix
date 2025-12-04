{
  config,
  lib,
  flake-parts-lib,
  inputs,
  ...
}:
let
  inherit (lib) types mkOption literalExpression;
  inherit (flake-parts-lib) mkPerSystemOption;

  rootConfig = config;

  containerAttrsOf =
    elemType:
    types.attrsWith {
      lazy = true;
      placeholder = "container";
      inherit elemType;
    };
in
{
  options.perSystem = mkPerSystemOption (
    { pkgs, config, ... }:
    {
      options.nix2gpu = mkOption {
        description = ''
          `nix2gpu` is a Nix-based container runtime that makes distributed GPU compute accessible and efficient.

          it provides reproducible environments with `cuda` 12.8, `tailscale` networking,
          and a modern development toolset, turning any gpu into a coherent compute cluster.

          `vast.ai` is the first supported platform, with more to come.

          key features:
          - **reproducible environments**: leverage the power of nix to create deterministic and portable container images.
          - **`cuda 12.8`**: comes with a full suite of `cuda` libraries, including `cudnn`, `nccl`, and `cublas`.
          - **`tailscale` networking**: seamlessly and securely connect your heterogeneous fleet of machines.
          - **modern development tools**: includes `gcc`, `python`, `uv`, `patchelf`, `tmux`, `starship`, and more.

          configuration options:
          take a look at config options for individual containers inside ${../config}
        '';
        example = literalExpression ''
          perSystem.nix2gpu.sample = { };
        '';
        type = containerAttrsOf (
          types.submodule (
            { name, ... }:
            {
              imports = lib.pipe ../config [
                builtins.readDir
                (lib.filterAttrs (_name: type: type == "regular"))
                builtins.attrNames
                (map (file: ../config/${file}))
              ];

              options = {
                name = mkOption {
                  type = types.str;
                  internal = true;
                  default = name;
                };
                rootConfig = mkOption {
                  internal = true;
                  default = rootConfig;
                };
                systemConfig = mkOption {
                  internal = true;
                  default = config;
                };
                pkgs = mkOption {
                  internal = true;
                  default = pkgs;
                };
              };

              config._module.args = { inherit inputs; };
            }
          )
        );
      };
    }
  );
}
