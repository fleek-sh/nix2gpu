{
  perSystem =
    { self', pkgs, ... }:
    {
      checks.executableByContainerRuntime = pkgs.testers.runNixOSTest {
        name = "executable-by-container-runtime";
        nodes.containerRunner = _: {
          virtualisation = {
            podman.enable = true;
            diskSize = 32000;
          };

          environment.systemPackages = [ self'.packages."nginx-test".copyToPodman ];

          system.stateVersion = "25.11";
        };

        testScript = ''
          machine.wait_for_unit("default.target")

          machine.succeed("copy-to-podman")
          machine.succeed("podman run -d -p 8080:8080 nginx-test:latest")
          machine.sleep(2)

          machine.wait_for_open_port(8080, timeout=30)
        '';
      };
    };
}
