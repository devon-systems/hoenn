_: {
  flake.darwinModules.fallarbor = {
    networking = let
      hostName = "fallarbor";
    in {
      inherit hostName;
      computerName = hostName;
      localHostName = hostName;
    };
  };
}
