{
  # This example includes the
  # `registry` attribute,
  # which allows the use of scripts like
  # `nix run .#with-registry.copyToGithub`
  perSystem.nix2vast."with-registry" = {
    registry = "ghcr.io/fleek-platform";
  };
}
