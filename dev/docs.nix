{ inputs, ... }:
{
  imports = [ inputs.flake-parts-website.flakeModules.empty-site ];

  perSystem.render.inputs.self = {
    baseUrl = "https://github.com/fleek-platform/nix2vast/blob/main";
    title = "nix2vast";
    intro = ''
      nix2vast documentation
    '';
    separateEval = true;
    extraInputs = inputs;
  };
}
