_: {
  flake.nixosModules.lavaridge = {pkgs, ...}: {
    services.ollama = {
      enable = true;
      host = "127.0.0.1";
      openFirewall = false;
      package = pkgs.ollama-rocm;

      environmentVariables = {
        OLLAMA_NO_CLOUD = "1";
        OLLAMA_IGPU_ENABLE = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
        OLLAMA_MAX_LOADED_MODELS = "1";
        OLLAMA_NUM_PARALLEL = "2";
        OLLAMA_MAX_QUEUE = "8";
        OLLAMA_CONTEXT_LENGTH = "65536";
      };
    };
  };
}
