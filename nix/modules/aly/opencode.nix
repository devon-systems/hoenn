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
          "Qwen3.8-Flash-Next-Halogen" = {
            name = "Qwen 3.8 Flash Next (Halogen)";
            limit.context = 262144;
          };
          "Qwen3.8-27B-DFlash-GGUF" = {
            name = "Qwen 3.8 27B DFlash (Lemonade)";
            limit.context = 65536;
          };
          "Qwen3.6-35B-A3B-MTP-GGUF" = {
            name = "Qwen 3.6 35B A3B MTP (Lemonade)";
            limit.context = 65536;
          };
          "Muse-Glimmer-30B-GGUF" = {
            name = "Muse Glimmer 30B (Lemonade)";
            limit.context = 65536;
          };
        };
      };
    };
  };
}
