{
  age = {
    identityPaths = [ "/root/.ssh/id_ed25519" ];
    secrets = {
      hello-world = {
        file = ../../../secrets/hello-world.age;
      };
    };
  };
}
