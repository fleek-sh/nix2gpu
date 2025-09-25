{ inputs, config, ... }:
{
  imports = [
    inputs.agenix.homeManagerModules.default
  ];

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

  home.activation.createAgenixDir = ''
    mkdir -p /root/agenix
    mkdir -p /root/agenix.d

    cat << EOF > /root/agenix/hello-world.age
    ${config.age.secrets.hello-world.file}
    EOF
  '';
}
