{inputs, ...}: {
  flake = {
    nixosModules.desktop = {
      imports = [inputs.openlogi.nixosModules.default];

      programs.openlogi = {
        enable = true;
        launchAtLogin = true;
      };
    };

    darwinModules.desktop = {
      homebrew.casks = ["openlogi"];
    };
  };
}
