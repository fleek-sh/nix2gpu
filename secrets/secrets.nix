let
  users = {
    baileylu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAmCgBNVyIGsjKG4191p/8sErRtOkeBRdbQSg9ondkAW baileylu@tcd.ie";
  };

  systems = {
    # example-system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJDyIr/FSz1cJdcoW69R+NrWzwGK/+3gJpqD1t8L2zE";
  };
in
{
  "hello-world.age".publicKeys = builtins.attrValues users ++ builtins.attrValues systems;
}
