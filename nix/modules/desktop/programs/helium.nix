{inputs, ...}: {
  flake = {
    nixosModules.desktop = {
      imports = [inputs.helium-browser.nixosModules.default];

      programs.helium.enable = true;
    };

    darwinModules.desktop = {
      homebrew.casks = ["helium-browser"];
    };
  };
}
