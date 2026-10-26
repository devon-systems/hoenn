_: {
  flake.darwinModules.darwin = {
    homebrew = {
      enable = true;
      global.autoUpdate = true;

      onActivation = {
        upgrade = true;
      };
    };
  };
}
