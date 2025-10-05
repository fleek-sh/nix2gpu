{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.hf-nix.overlays.default ];
        config = {
          cudaSupport = true;
          allowUnfree = true;
          rocmSupport = false;
        };
      };
    };
}
