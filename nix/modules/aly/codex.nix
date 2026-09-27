{inputs, ...}: {
  flake.homeModules.aly = {pkgs, ...}: {
    programs.codex = {
      enable = true;
      enableMcpIntegration = true;
      # package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    };
  };
}
