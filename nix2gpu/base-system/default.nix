{
  config,
  lib,
  pkgs,
  ...
}:
let

  mkFileCreator =
    name: outLocation: contents:
    pkgs.resholve.writeScriptBin name
      {
        interpreter = lib.getExe pkgs.bash;
        inputs = [ pkgs.coreutils ];
      }
      ''
        set -euo pipefail

        mkdir -p "$(dirname ${outLocation})"

        cat >${outLocation} <<'EOF'
        ${contents}
        EOF
      '';

  writeLd =
    pkgs.resholve.writeScriptBin "write-ld"
      {
        interpreter = lib.getExe pkgs.bash;
        inputs = [ pkgs.coreutils ];
      }
      ''
        set -euo pipefail

        mkdir -p "$out/lib64"

        ln -s "${pkgs.glibc}/lib64/ld-linux-x86-64.so.2" "$out/lib64/ld-linux-x86-64.so.2"
      '';

  script = pkgs.resholve.writeScriptBin "create-base-system" {
    interpreter = lib.getExe pkgs.bash;
    inputs =
      with pkgs;
      [
        coreutils
        which
        plocate
      ]
      ++ [
        (mkFileCreator "write-passwd" "$out/etc/passwd" config.nix2gpuPasswdContents)
        (mkFileCreator "write-group" "$out/etc/group" config.nix2gpuGroupContents)
        (mkFileCreator "write-shadow" "$out/etc/shadow" config.nix2gpuShadowContents)
        (mkFileCreator "write-nix" "$out/etc/nix/nix.conf" config.nixConfig)
        (mkFileCreator "write-sshd" "$out/etc/ssh/sshd_config" config.sshdConfig)
        writeLd
      ];
    prologue =
      (pkgs.writeText "setup-glibc" ''
        export PATH="${pkgs.glibc.bin}/bin:$PATH"
      '').outPath;
  } (builtins.readFile ./create-base-system.sh);
in
{
  config.nimiSettings.container.copyToRoot = pkgs.runCommandLocal "base-system" { } (
    lib.getExe script
  );
}
