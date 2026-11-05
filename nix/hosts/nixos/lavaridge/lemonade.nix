{inputs, ...}: {
  flake.nixosModules.lavaridge = {pkgs, ...}: let
    modelRevision = "d96201194f103c906994f283f504209dc8d2a10c";
    modelCache = "/var/lib/lemonade/models/hf/hub";
    modelDirectory = "${modelCache}/models--unsloth--Qwen3.8-Flash-Next-GGUF/snapshots/${modelRevision}/UD-IQ1_M";
  in {
    imports = [inputs.nix-amd-ai.nixosModules.default];

    hardware.amd-npu = {
      enable = true;
      enableNPU = false;
      enableFastFlowLM = false;
      enableImageGen = false;
      enableROCm = true;
      gpuTarget = "gfx1151";
      # Default is 31 GiB. 44 lets the expert cache grow while reserving
      # the remaining unified memory for Linux and the desktop.
      gpuMemory.ttmSizeGiB = 44;
      # GSQHalo's gfx1151 kernels beat stock ROCm and Vulkan on prompt
      # processing for the two dense GGUFs served below.
      llamaCppRocmPackage = pkgs.llama-cpp-rocm-gsqhalo;

      lemonade = {
        user = "lemonade";
        cacheDir = "/var/lib/lemonade/models";
        desktopApp.enable = false;
        # The firewall only trusts Tailscale and Hoenn WireGuard, so this
        # stays off the LAN while other Hoenn hosts can reach the API.
        host = "0.0.0.0";
        port = 13305;
        autoStart = true;

        models = [
          "Muse-Glimmer-30B-GGUF"
          "user.Qwen3.8-27B-DFlash-GGUF"
        ];
        customModels."Qwen3.8-27B-DFlash-GGUF" = {
          checkpoints = {
            main = "unsloth/Qwen3.8-27B-GGUF:Qwen3.8-27B-UD-Q4_K_XL.gguf";
            mmproj = "unsloth/Qwen3.8-27B-GGUF:mmproj-F16.gguf";
            draft = "ggml-org/Qwen3.8-27B-GGUF:dflash-Qwen3.8-27B-Q8_0.gguf";
          };
          recipe = "llamacpp";
          labels = ["chat" "reasoning" "vision" "tool-calling" "dflash"];
          recipe_options = {
            ctx_size = 262144;
            llamacpp_args = "--batch-size 4096 --ubatch-size 2048 --cache-type-k q8_0 --cache-type-v q8_0 --spec-draft-n-max 5";
          };
        };

        settings = {
          max_loaded_models = 1;
          # Global must stay false: it gates VRAM-pressure polling, and this
          # model's own resident footprint exceeds the 90% threshold.
          auto_evict = false;
          # Not an idle timer: this caps HTTP/inference/readiness requests.
          # 0 disables the cap so long agent runs survive (nix-amd-ai #1364).
          global_timeout = 0;
          auto_update_models = false;
          auto_check_model_updates = true;
          telemetry.enabled = false;
          llamacpp.backend = "rocm";
        };

        # Per-model true keeps idle eviction after an hour while the global
        # false above disables pressure polling. Reload is transparent — a
        # request that arrives mid-eviction interrupts it and is served.
        recipeOptions = {
          "builtin.Muse-Glimmer-30B-GGUF" = {
            auto_evict = true;
            evict_idle_timeout = 3600;
            ctx_size = 131072;
            llamacpp_args = "--batch-size 4096 --ubatch-size 2048 --cache-type-k q8_0 --cache-type-v q8_0 --spec-draft-n-max 3";
          };
          "user.Qwen3.8-27B-DFlash-GGUF" = {
            auto_evict = true;
            evict_idle_timeout = 3600;
          };
          "user.Qwen3.8-Flash-Next-Strata" = {
            auto_evict = true;
            evict_idle_timeout = 3600;
          };
        };
      };

      strata = {
        enable = true;
        model = "${modelDirectory}/Qwen3.8-Flash-Next-UD-IQ1_M-00001-of-00003.gguf";
        profile = "fast";
        # The pinned engine cannot expand IQ2_XS's draft head in place to Q4_0.
        extraArgs = [
          "--mtp-q4"
          "proj"
          "--prompt-cache"
          "8"
          "--conversation-cache-mib"
          "2048"
          "--conversation-cache-slots"
          "4"
          "--conversation-cache-min-tokens"
          "512"
          "--conversation-cache-min-free-mib"
          "8192"
        ];
        contextSize = 65536;
        # 17700 budgets slightly more bytes than the full IQ1 expert set.
        # 14700 measured 20480 resident experts with healthy free RAM.
        expertCache = 17700;
        vision.enable = true;
      };
    };

    systemd.services.lemond.environment.STRATA_PREFILL_STREAM_MIN = "128";

    systemd.services.strata-model-download = {
      description = "Download the pinned Strata UD-IQ1_M model";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        User = "lemonade";
        RemainAfterExit = true;
        TimeoutStartSec = "infinity";
        ExecStart = pkgs.writeShellScript "strata-model-download" ''
          if test -f "${modelDirectory}/Qwen3.8-Flash-Next-UD-IQ1_M-00001-of-00003.gguf" &&
             test -f "${modelDirectory}/Qwen3.8-Flash-Next-UD-IQ1_M-00002-of-00003.gguf" &&
             test -f "${modelDirectory}/Qwen3.8-Flash-Next-UD-IQ1_M-00003-of-00003.gguf"; then
            exit 0
          fi
          exec ${pkgs.huggingface-cli}/bin/hf download unsloth/Qwen3.8-Flash-Next-GGUF \
            --revision ${modelRevision} --include 'UD-IQ1_M/*' --cache-dir ${modelCache}
        '';
      };
    };

    systemd.services.strata-prepare = {
      requires = ["strata-model-download.service"];
      after = ["strata-model-download.service"];
    };

    users = {
      groups.lemonade = {};

      users.lemonade = {
        isSystemUser = true;
        group = "lemonade";
        extraGroups = ["render" "video"];
        home = "/var/lib/lemonade";
        createHome = true;
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/lemonade/models 0750 lemonade lemonade -"
      "d /var/lib/lemonade/models/hf 0750 lemonade lemonade -"
      "d /var/lib/lemonade/models/lemonade 0750 lemonade lemonade -"
    ];

    nix.settings = {
      substituters = ["https://nix-amd-ai.cachix.org"];
      trusted-public-keys = ["nix-amd-ai.cachix.org-1:F4OU4vw/lV2oiG6SBHZ+nqjl4EFJuqI4X9A7pvaBmhQ="];
    };
  };
}
