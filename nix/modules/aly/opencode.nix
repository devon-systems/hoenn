{inputs, ...}: {
  flake.homeModules.aly = {pkgs, ...}: {
    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;

      settings = {
        plugin = [
          "opencode-openai-codex-auth"
          "@warp-dot-dev/opencode-warp"
        ];

        small_model = "opencode/big-pickle";

        agent = {
          explore.model = "opencode/big-pickle";
          scout.model = "opencode/big-pickle";
        };
      };

      tui.theme = "catppuccin-frappe";
    };
  };
}
