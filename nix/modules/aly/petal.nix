{inputs, ...}: {
  flake.homeModules.aly = {
    imports = [inputs.petal.homeManagerModules.default];

    programs.petal = {
      enable = true;
      enableMcpIntegration = true;
      settings = {
        transparent_background = true;
        history.embeddings = {
          provider = "ollama";
          base_url = "https://lavaridge.narwhal-snapper.ts.net";
          model = "embeddinggemma-2";
        };
      };
    };
  };
}
