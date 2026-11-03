{inputs, ...}: {
  flake.homeModules.aly = {pkgs, ...}: {
    programs.codex = {
      enable = true;
      enableMcpIntegration = true;
      mutableSettings = true;

      settings = {
        approval_policy = "never";
        default_permissions = ":danger-full-access";
        features.code_mode = true;
        # Avoid blocking startup on desktop keyring access in SSH sessions.
        mcp_oauth_credentials_store = "file";
      };

      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    };
  };
}
