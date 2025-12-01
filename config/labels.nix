{ config, lib, ... }:
let
  inherit (lib) types mkOption;
  inherit (config) systemConfig name;
in
{
  options.labels = mkOption {
    description = ''
      A set of labels to apply to the container.

      This option allows you to define metadata for the container in the form
      of labels. These labels can be used for organizing and filtering
      containers, or for storing information about the container's contents
      or purpose.

      The default value includes several labels that provide information
      about the container's origin, runtime, and dependencies.

      If you want to add extra labels without replacing the default set,
      use the `extraLabels` option instead.

      > This is a direct mapping to the `Labels` attribute of the [oci container
      > spec](https://github.com/opencontainers/image-spec/blob/8b9d41f48198a7d6d0a5c1a12dc2d1f7f47fc97f/specs-go/v1/config.go#L23). 
    '';

    example = ''
      labels = {
        "my.custom.label" = "some-value";
        "another.label" = "another-value";
      };
    '';
    type = types.attrsOf types.str;
    default = {
      "ai.vast.gpu" = "required";
      "ai.vast.runtime" = "nix2gpu";
      "com.nvidia.volumes.needed" = "nvidia_driver";
      "com.nvidia.cuda.version" = systemConfig.nix2gpu.${name}.cudaPackages.cudatoolkit.version;
      "org.opencontainers.image.source" = "https://github.com/weyl-ai/nix2gpu";
      "org.opencontainers.image.description" = "Nix-based GPU container with Tailscale mesh";
    };
    defaultText = ''
      "ai.vast.gpu" = "required";
      "ai.vast.runtime" = "nix2gpu";
      "com.nvidia.volumes.needed" = "nvidia_driver";
      "com.nvidia.cuda.version" = systemConfig.nix2gpu.<name>.cudaPackages.cudatoolkit.version;
      "org.opencontainers.image.source" = "https://github.com/weyl-ai/nix2gpu";
      "org.opencontainers.image.description" = "Nix-based GPU container with Tailscale mesh";
    '';
  };
}
