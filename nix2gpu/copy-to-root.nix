{ config, lib, ... }:
let
  inherit (lib)
    types
    mkOption
    literalExpression
    literalMD
    ;

  excludedDirs = [
    "tmp"
    "run"
    "var"
    "proc"
    "dev"
    "nix"
    "sys"
    "etc"
    "root"
    "home"
  ];

  # For bubblewrap, we need to bind each subdirectory from copyToRoot packages
  # individually, since --ro-bind doesn't overlay contents like container layers do.
  # This creates binds like: /nix/store/xxx-base-system/bin -> /bin
  copyToRootBinds = lib.concatMap (
    pkg:
    lib.pipe (builtins.readDir pkg) [
      builtins.attrNames
      (lib.filter (e: !builtins.elem e excludedDirs))
      (map (entry: {
        src = "${pkg}/${entry}";
        dest = "/${entry}";
      }))
    ]
  ) config.copyToRoot;
in
{
  _class = "nix2gpu";

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
    example = literalExpression ''
      copyToRoot = with pkgs; [
        coreutils
        git
      ];
    '';
    type = types.coercedTo types.pathInStore (p: [ p ]) (types.listOf types.pathInStore);
    default = [ ];
    defaultText = literalMD ''
      The generated base system from the other config options
    '';
  };

  config.nimiSettings = {
    container.copyToRoot = config.copyToRoot;
    bubblewrap.tryRoBinds = lib.mkAfter (
      copyToRootBinds
      ++ [
        {
          src = "/nix/var/nix/daemon-socket";
          dest = "/nix/var/nix/daemon-socket";
        }
        {
          src = "/lib/x86_64-linux-gnu";
          dest = "/lib/x86_64-linux-gnu";
        }
        {
          src = "/usr/lib/x86_64-linux-gnu";
          dest = "/usr/lib/x86_64-linux-gnu";
        }
        {
          src = "/usr/bin/nvidia-smi";
          dest = "/usr/bin/nvidia-smi";
        }
      ]
    );
    bubblewrap.extraTmpfs = [
      "/root"
      "/home"
    ];
    bubblewrap.environment.NIX_REMOTE = "daemon";
    # Disable --proc /proc and bind host's /proc instead for GPU driver access
    # NVIDIA driver requires /proc/driver/nvidia which only exists in host's procfs
    # Use prependFlags to ensure /proc is bound early (before --dev /dev)
    bubblewrap.bind.proc = false;
    bubblewrap.prependFlags = [
      "--ro-bind"
      "/proc"
      "/proc"
    ];
    bubblewrap.tryDevBinds = [
      {
        src = "/dev/nvidiactl";
        dest = "/dev/nvidiactl";
      }
      {
        src = "/dev/nvidia-modeset";
        dest = "/dev/nvidia-modeset";
      }
      {
        src = "/dev/nvidia-uvm";
        dest = "/dev/nvidia-uvm";
      }
      {
        src = "/dev/nvidia-uvm-tools";
        dest = "/dev/nvidia-uvm-tools";
      }
      {
        src = "/dev/nvidia0";
        dest = "/dev/nvidia0";
      }
      {
        src = "/dev/nvidia1";
        dest = "/dev/nvidia1";
      }
      {
        src = "/dev/nvidia2";
        dest = "/dev/nvidia2";
      }
      {
        src = "/dev/nvidia3";
        dest = "/dev/nvidia3";
      }
      {
        src = "/dev/nvidia4";
        dest = "/dev/nvidia4";
      }
      {
        src = "/dev/nvidia5";
        dest = "/dev/nvidia5";
      }
      {
        src = "/dev/nvidia6";
        dest = "/dev/nvidia6";
      }
      {
        src = "/dev/nvidia7";
        dest = "/dev/nvidia7";
      }
      {
        src = "/dev/nvidia-caps";
        dest = "/dev/nvidia-caps";
      }
      {
        src = "/dev/dri";
        dest = "/dev/dri";
      }
    ];
  };
}
