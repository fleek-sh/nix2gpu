{ config, lib, ... }:
let
  inherit (lib) types mkOption;
  inherit (config) systemConfig name;
in
{
  options.copyToRoot = mkOption {
    description = ''
      A list of packages to be copied to the root of the container.

      This option allows you to specify a list of Nix packages that will be
      symlinked into the root directory of the container. This is useful for
      making essential packages and profiles available at the top level of the
      container's filesystem.

      The default value includes the base system, the container's profile, and the
      Nix store profile, which are essential for the container to function correctly.

      If you want to add extra packages without replacing the default set,
      use the `extraCopyToRoot` option instead.

      > This is a direct mapping to the
      > [`copyToRoot`](https://github.com/nlewo/nix2container?tab=readme-ov-file#nix2containerbuildimage)
      > attribute from [`nix2container`](https://github.com/nlewo/nix2container).
    '';
    example = ''
      copyToRoot = with pkgs; [
        coreutils
        git
      ];
    '';
    type = types.listOf types.package;
    default = with systemConfig; [
      allContainers.${name}.baseSystem
      allContainers.${name}.profile
      nix2vastNixStoreProfile
    ];
    defaultText = ''
      The generated base system from the other config options
    '';
  };
}
