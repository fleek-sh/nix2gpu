{
  # This example shows how one may use
  # [agenix](https://github.com/ryantm/agenix)
  # config options via the `age` attribute
  perSystem.nix2gpu."agenix" = {
    age.secrets.tailscale-key = {
      file = ./secrets/ts-key.age;
      path = "/run/secrets/ts-key";
    };
  };
}
