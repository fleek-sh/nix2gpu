{ self, ... }:
{
  flake.templates.default = {
    path = "${self}/templates/default";
    welcomeText = ''
      welcome to `nix2gpu`, providing `nixos` containers for cost-effective and capable gpu compute.

      run your first container with

      - `nix run .#basic.copyToDockerDaemon`

      - `nix run .#basic.shell`
    '';
    description = "default nix2gpu template";
  };
}
