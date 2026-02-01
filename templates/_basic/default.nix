{ inputs, ... }:
{
  imports = [ inputs.nix2gpu.flakeModule ];

  perSystem.nix2gpu.basic = {
    registries = [ "ghcr.io/weyl-ai" ];
  };
}
