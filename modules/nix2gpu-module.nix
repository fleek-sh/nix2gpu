{ inputs, ... }:
let
  inherit (inputs) import-tree;
in
{
  flake.modules.nix2gpu.default = _: import-tree ../nix2gpu;
}
