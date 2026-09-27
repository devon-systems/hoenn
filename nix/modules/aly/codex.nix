_: {
  flake.homeModules.aly = _: {
    programs.codex = {
      enable = true;
      enableMcpIntegration = true;
      # package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    };
  };
}
