_: {
  flake.homeModules.aly = {
    programs.nix-your-shell = {
      enable = true;
      nix-output-monitor.enable = true;
    };
  };
}
