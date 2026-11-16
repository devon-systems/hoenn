{inputs, ...}: {
  flake.systemModules.systemManager = {pkgs, ...}: {
    environment.systemPackages = [inputs.system-manager.packages.${pkgs.stdenv.hostPlatform.system}.default];
  };
}
