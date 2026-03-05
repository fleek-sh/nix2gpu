{
  perSystem =
    { self', pkgs, ... }:
    let
      containerName = "http-test";
    in
    {
      checks.executable-by-bubblewrap = pkgs.testers.runNixOSTest {
        name = "executable-by-bubblewrap";
        nodes.bubblewrapRunner = _: {
          # Enable unprivileged user namespaces for bubblewrap
          boot.kernel.sysctl."kernel.unprivileged_userns_clone" = 1;

          environment.systemPackages = [
            self'.packages.${containerName}.runInBubblewrap
            pkgs.curl
          ];

          system.stateVersion = "25.11";
        };

        testScript = ''
          machine.wait_for_unit("default.target")

          machine.execute("nohup nimi-sandbox > /tmp/nimi-sandbox.log 2>&1 &")

          machine.wait_for_open_port(8080, timeout=30)

          output = machine.succeed("curl -s http://localhost:8080")
          print(f"Server output: {output}")
          assert "Index of" in output, f"Expected 'Index of' in response, got: {output}"

          machine.wait_for_open_port(2222, timeout=30)

          machine.execute("cat /tmp/nimi-sandbox.log")
        '';
      };
    };
}
