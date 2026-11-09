{inputs, ...}: {
  flake = {
    nixosModules.desktop = {
      # nixpkgs ships a narrower programs.openlogi module without launchAtLogin.
      disabledModules = ["programs/openlogi.nix"];
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
