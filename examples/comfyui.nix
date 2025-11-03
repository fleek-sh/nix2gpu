{
  # This example shows how one may run
  # [comfyui](https://www.comfy.org/)
  # with `nix2vast`
  perSystem.nix2vast."comfyui-service" = {
    services.comfyui."comfyui-example".enable = true;
  };
}
