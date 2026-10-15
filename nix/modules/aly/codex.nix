_: {
  flake.homeModules.aly = {inputs, pkgs, ...}: {
    programs.codex = {
      enable = true;
      enableMcpIntegration = true;
      mutableSettings = true;

      settings = {
        approval_policy = "never";
        sandbox_mode = "danger-full-access";
      };

      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    };
  };
}
