{
  perSystem =
    { self', pkgs, ... }:
    {
      checks.executable-by-container-runtime = pkgs.testers.runNixOSTest {
        name = "executable-by-container-runtime";
        nodes.containerRunner = _: {
          virtualisation = {
            podman.enable = true;
            diskSize = 32000;
          };

          environment.systemPackages = [ self'.packages."http-test".copyToContainerRuntime ];

          system.stateVersion = "25.11";
        };

        testScript = ''
          machine.wait_for_unit("default.target")

          machine.succeed("copy-to-container-runtime")
          machine.succeed("podman run -d -p 8080:8080 https-test:latest")
          machine.sleep(2)

          machine.wait_for_open_port(8080, timeout=30)
        '';
      };
    };
}
