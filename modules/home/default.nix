{ inputs, ... }:
{
  imports = [ inputs.home-manager.flakeModules.default ];

  perSystem = _: {
    perContainer =
      { container, ... }:
      builtins.trace "options: ${container.name}" {
        container.homeConfigurations."${container.name}-home" = container.options.home;
      };
  };
}
