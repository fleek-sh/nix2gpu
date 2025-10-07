{ config, lib, ... }:
let
  inherit (lib) types mkOption;
  inherit (config) systemConfig name;
in
{
  options.labels = mkOption {
    description = ''
      container labels to set.

      looking to add labels without effecting the
      default set? see `extraLabels`.
    '';
    type = types.attrsOf types.str;
    default = {
      "ai.vast.gpu" = "required";
      "ai.vast.runtime" = "nix2vast";
      "com.nvidia.volumes.needed" = "nvidia_driver";
      "com.nvidia.cuda.version" = systemConfig.nix2vast.${name}.cudaPackages.cudatoolkit.version;
      "org.opencontainers.image.source" = "https://github.com/fleek-platform/nix2vast";
      "org.opencontainers.image.description" = "Nix-based GPU container with Tailscale mesh";
    };
  };
}
