{
  # This example shows how one may run
  # [comfyui](https://www.comfy.org/)
  # with `nix2gpu`
  perSystem =
    { pkgs, ... }:
    {
      nix2gpu."comfyui-service" = {
        services.comfyui."comfyui-example" = {
          enable = true;
          models = [ pkgs.nixified-ai.models.stable-diffusion-v1-5 ];
        };

        registry = "ghcr.io/fleek-platform";

        exposedPorts = {
          "22/tcp" = { };
          "8188/tcp" = { };
          "8188/udp" = { };
        };
      };
    };
}
