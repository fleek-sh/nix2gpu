{
  description = "nix2vast - nixos containers optimized for vast.ai compute";

  inputs = {
    # TODO: Return to actual nixpkgs once this is merged
    nixpkgs.url = "github:baileyluTCD/nixpkgs?ref=init-vastai";
    hf-nix.url = "github:huggingface/hf-nix";

    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    nix2container = {
      # TODO: Return to actual nix2container once this is merged
      url = "github:baileylutcd/nix2container?ref=add-passthru-attribute";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    services-flake.url = "github:juspay/services-flake";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://cache.garnix.io"
      "https://huggingface.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "huggingface.cachix.org-1:ynTPbLS0W8ofXd9fDjk1KvoFky9K2jhxe6r4nXAkc/o="
    ];
  };

  outputs =
    { flake-parts, import-tree, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      let
        module = import-tree ./modules;
      in
      {
        flake.flakeModule = module;

        systems = import inputs.systems;

        imports = [
          module
          (import-tree ./examples)
          (import-tree ./dev)
          (import-tree ./checks)
        ];
      }
    );
}
