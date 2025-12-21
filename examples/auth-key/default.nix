{
  # This example shows how one may use
  # [agenix](https://github.com/ryantm/agenix)
  # config options via the `age` attribute
  perSystem.nix2gpu."auth-key" =
    { config, ... }:
    {
      age.enable = true;
      age.secrets.tailscale-key = {
        file = ./_secrets/example.age;
        path = "/run/secrets/example";
      };

      tailscale = {
        enable = true;
        authKey = config.age.secrets.tailscale-key.path;
      };
    };
}
