_: {
  flake.homeModules.aly = {
    programs.herdr = {
      enable = true;
      mutableSettings = true;

      settings = {
        onboarding = false;
      };
    };
  };
}
