{
  # This example shows how one may use
  # [agenix](https://github.com/ryantm/agenix)
  # config options via the `age` attribute
  perSystem.nix2gpu."agenix" = {
    age.secrets.tailscale-key = {
      file = ./example.age;
      path = "/run/secrets/example";
    };
  };
}
