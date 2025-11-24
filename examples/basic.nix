{
  # Try running `nix build .#basic`
  # to build the container.
  #
  # This derivation also exposes some scripts,
  # for example, running `nix build .#basic.copyToGithub`
  # will copy it to it's github registry.
  perSystem.nix2vast.basic = { };
}
