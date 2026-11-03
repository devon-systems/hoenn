{inputs, ...}: {
  flake.nixosModules.openlogi = {
    imports = [inputs.openlogi.nixosModules.default];

    programs.openlogi = {
      enable = true;
      launchAtLogin = true;
    };
  };
}
