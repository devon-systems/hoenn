{inputs, ...}: {
  flake.homeModules.aly = {pkgs, ...}: {
    programs.codex = {
      enable = true;
      enableMcpIntegration = true;
      mutableSettings = true;

      settings = {
        approval_policy = "never";
        default_permissions = ":danger-full-access";
      };

      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    };
  };
}
