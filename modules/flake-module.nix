_:
let

  flakeModule =
    { lib, flake-parts-lib, ... }:
    let
      inherit (flake-parts-lib) mkPerSystemOption;
      inherit (lib) mkOption types;
    in
    {
      options.perSystem = mkPerSystemOption {
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
          type = types.lazyAttrsOf types.raw;
        };
      };

      config.perSystem =
        { config, ... }:
        let
          generatedNix2gpuPkgs = lib.mapAttrs config.mkNix2GpuContainer config.nix2gpu;
        in
        {
          packages = generatedNix2gpuPkgs;
          checks = generatedNix2gpuPkgs;
        };
    };
in
{
  imports = [ flakeModule ];

  flake = { inherit flakeModule; };
}
