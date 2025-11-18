{
  inputs,
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types mkOption;
  inherit (flake-parts-lib) mkPerSystemOption;

  rootConfig = config;
in
{
  options.perSystem = mkPerSystemOption (
    { pkgs, config, ... }:
    {
      options.nix2vast = mkOption {
        description = ''
          `nix2vast` is a Nix-based container runtime that makes distributed GPU compute accessible and efficient.

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
        example = ''
          perSystem.nix2vast.sample = { };
        '';
        type = types.attrsOf (
          types.submodule (
            { name, ... }:
            {
              imports = [ (inputs.import-tree ../config) ];

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
            }
          )
        );
      };
    }
  );
}
