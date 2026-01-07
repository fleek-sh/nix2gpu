{
  description = "nix2gpu - nixos containers optimized for vast.ai compute";

  inputs = {
    # TODO: Return to actual nixpkgs once this is merged
    nixpkgs.url = "github:weyl-ai/nixpkgs?ref=handle-code-nixos-render-doc";

    systems.url = "github:nix-systems/x86_64-linux";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixified-ai = {
      url = "github:nixified-ai/flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    ndg = {
      url = "github:feel-co/ndg";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nimi = {
      url = "git+ssh://git@github.com/weyl-ai/nimi.git?ref=baileylu/random-fixes";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.systems.follows = "systems";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.ndg.follows = "ndg";
    };

    nix2container.follows = "nimi/nix2container";
  };

  nixConfig = {
    extra-substituters = [ "https://weyl-ai.cachix.org" ];
    extra-trusted-public-keys = [ "weyl-ai.cachix.org-1:cR0SpSAPw7wejZ21ep4SLojE77gp5F2os260eEWqTTw=" ];
  };

  outputs =
    { flake-parts, import-tree, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (import-tree [
      ./examples
      ./dev
      ./checks
      ./modules
    ]);
}
