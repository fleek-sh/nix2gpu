{
  age = {
    identityPaths = [ "/root/.ssh/id_ed25519" ];

    secrets = {
      hello-world = {
        file = ../../../secrets/hello-world.age;
      };
    };

    secretsDir = "/root/agenix";
    secretsMountPoint = "/root/agenix.d";
  };
}
