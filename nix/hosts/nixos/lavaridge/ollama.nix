_: {
  flake.nixosModules.lavaridge = {pkgs, ...}: {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      loadModels = ["embeddinggemma-2"];

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

    services.caddy = {
      enable = true;
      virtualHosts."http://:11435".extraConfig = ''
        bind 127.0.0.1
        @embeddings path /api/tags /api/embed
        handle @embeddings {
          reverse_proxy 127.0.0.1:11434
        }
        handle {
          respond 404
        }
      '';
    };

    systemd.services.ollama-embeddings-tailnet = {
      description = "Serve Ollama embeddings over tailnet HTTPS";
      wantedBy = ["multi-user.target"];
      after = ["tailscaled.service" "caddy.service"];
      wants = ["tailscaled.service" "caddy.service"];
      serviceConfig = {
        ExecStart = "${pkgs.tailscale}/bin/tailscale serve --yes http://127.0.0.1:11435";
        Restart = "always";
        RestartSec = "5s";
      };
    };
  };
}
