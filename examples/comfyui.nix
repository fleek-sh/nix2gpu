{ lib, ... }:
{
  # This example shows how one may run
  # [comfyui](https://www.comfy.org/)
  # with `nix2gpu`
  perSystem =
    { pkgs, ... }:
    {
      nix2gpu."comfyui-service" = {
        services."comfyui-example" = {
          imports = [ (lib.modules.importApply ../services/comfyui.nix { inherit pkgs; }) ];
          comfyui.models = [ pkgs.nixified-ai.models.stable-diffusion-v1-5 ];
        };

        registries = [ "ghcr.io/weyl-ai" ];

        exposedPorts = {
          "22/tcp" = { };
          "8188/tcp" = { };
          "8188/udp" = { };
        };
      };
    };
}
