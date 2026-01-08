{ name, ... }:
{
  _class = "nix2gpu";

  nimiSettings.container = { inherit name; };
}
