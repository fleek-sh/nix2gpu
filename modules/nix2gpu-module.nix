{ inputs, ... }:
{
  flake.modules.nix2gpu.default = inputs.import-tree ../nix2gpu;
}
