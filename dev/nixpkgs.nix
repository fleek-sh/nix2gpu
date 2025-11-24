{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.nixified-ai.overlays.comfyui
          inputs.nixified-ai.overlays.models
          inputs.nixified-ai.overlays.fetchers
        ];
        config = {
          cudaSupport = true;
          allowUnfree = true;
          rocmSupport = false;
        };
      };
    };
}
