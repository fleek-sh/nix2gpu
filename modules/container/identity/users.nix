{ lib, ... }:
{
  flake.modules.users =
    { pkgs, ... }:
    {
      root = {
        uid = 0;
        gid = 0;
        shell = "${pkgs.bashInteractive}/bin/bash";
        home = "/root";
        groups = [ "root" ];
        description = "System administrator";
      };

      sshd = {
        uid = 74;
        gid = 74;
        shell = "${pkgs.shadow}/bin/nologin";
        home = "/var/empty";
        groups = [ "sshd" ];
        description = "SSH daemon";
      };

      nobody = {
        uid = 65534;
        gid = 65534;
        shell = "${pkgs.shadow}/bin/nologin";
        home = "/var/empty";
        groups = [ "nobody" ];
        description = "Unprivileged account";
      }
      // lib.listToAttrs (
        map (n: {
          name = "nixbld${toString n}";
          value = {
            uid = 30000 + n;
            gid = 30000;
            groups = [ "nixbld" ];
            shell = "${pkgs.shadow}/bin/nologin";
            home = "/var/empty";
            description = "Nix build user ${toString n}";
          };
        }) (lib.lists.range 1 32)
      );
    };
}
