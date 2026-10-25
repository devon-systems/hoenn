{inputs, ...}: {
  flake.homeModules.aly = {
    config,
    pkgs,
    self,
    ...
  }: {
    sops.secrets.openwebui = {
      key = "api_key";
      sopsFile = self + "/secrets/openwebui.yaml";
    };

    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;

      settings.providers.kanto = {
        name = "Kanto";
        package = "@opencode/ai/providers/openai-compatible";
        settings = {
          baseURL = "https://openwebui.narwhal-snapper.ts.net/api";
          apiKey = "{file:${config.sops.secrets.openwebui.path}}";
        };
        models = {
          "Qwen3.8-Flash-Next-Strata" = {
            name = "Qwen Strata";
            limit.context = 262144;
          };
          "qwen3.8:latest" = {
            name = "Qwen 3.8 (Ollama)";
            limit.context = 65536;
          };
          "qwen3.6:35b-a3b-mtp-q4_K_M" = {
            name = "Qwen 3.6 35B A3B MTP (Ollama)";
            limit.context = 65536;
          };
          "muse-glimmer:latest" = {
            name = "Muse Glimmer (Ollama)";
            limit.context = 65536;
          };
          "gemma4:latest" = {
            name = "Gemma 4 (Ollama)";
            limit.context = 65536;
          };
        };
      };
    };
  };
}
