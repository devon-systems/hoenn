{inputs, ...}: {
  flake.homeModules.switchyard = {
    imports = [inputs.switchyard.homeManagerModules.switchyard];

    programs.switchyard.enable = true;
  };
}
