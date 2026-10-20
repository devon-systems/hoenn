_: {
  flake.homeModules.t3code = {
    programs.t3code = {
      enable = true;
      mutableClientSettings = true;
      mutableKeybindings = true;
      mutableUserSettings = true;
    };
  };
}
