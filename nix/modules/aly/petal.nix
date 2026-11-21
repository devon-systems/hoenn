{inputs, ...}: {
  flake.homeModules.aly = {
    imports = [inputs.petal.homeManagerModules.default];

    programs.petal = {
      enable = true;
      enableMcpIntegration = true;
      settings.transparent_background = true;
    };
  };
}
