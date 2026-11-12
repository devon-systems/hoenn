_: {
  flake = {
    nixosModules.desktop = {
      programs.openlogi.enable = true;
    };

    darwinModules.desktop = {
      homebrew.casks = ["openlogi"];
    };
  };
}
