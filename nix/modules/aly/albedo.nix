{inputs, ...}: {
  flake.homeModules.aly = {
    imports = [inputs.albedo.homeModules.default];

    programs.albedo.enable = true;
    services.albedo.enable = true;
  };
}
