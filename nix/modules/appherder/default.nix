{inputs, ...}: {
  flake.homeModules.appherder = {
    imports = [inputs.appherder.homeModules.appherder];

    programs.appherder.enable = true;

    services.appherder = {
      enable = true;
      upgrade.enable = true;
    };
  };
}
