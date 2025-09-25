{
  flake.modules.groups = {
    root.gid = 0;
    sshd.gid = 74;
    nobody.gid = 65534;
    nogroup.gid = 65534;
    nixbld.gid = 30000;
  };
}
