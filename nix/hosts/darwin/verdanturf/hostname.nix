_: {
  flake.darwinModules.verdanturf = {
    networking = let
      hostName = "verdanturf";
    in {
      inherit hostName;
      computerName = hostName;
      localHostName = hostName;
    };
  };
}
