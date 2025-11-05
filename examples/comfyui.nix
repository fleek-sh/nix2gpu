{
  # This example shows how one may run
  # [comfyui](https://www.comfy.org/)
  # with `nix2vast`
  perSystem.nix2vast."comfyui-service" = {
    services.comfyui."comfyui-example" = {
      enable = true;
    };

    registry = "ghcr.io/fleek-platform";

    exposedPorts = {
      "22/tcp" = { };
      "8188/tcp" = { };
      "8188/udp" = { };
    };
  };
}
