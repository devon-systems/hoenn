{inputs, ...}: {
  flake.homeModules.aly = {pkgs, ...}: {
    home.packages = [inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.muse-code];
  };
}
