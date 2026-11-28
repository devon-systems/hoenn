{inputs, ...}: {
  flake.homeModules.aly = {pkgs, ...}: {
    programs.antigravity-cli = {
      enable = true;
      enableMcpIntegration = true;
      mutableSettings = true;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.antigravity-cli;
    };
  };
}
