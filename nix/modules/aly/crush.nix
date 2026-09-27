{inputs, ...}: {
  flake.homeModules.aly = {pkgs, ...}: {
    programs.crush = {
      enable = true;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.crush;
    };
  };
}
