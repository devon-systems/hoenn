{inputs, ...}: {
  flake = {
    homeModules.hermesAgent = {
      config,
      lib,
      pkgs,
      self,
      ...
    }: let
      hermesPackage = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
        pmPackages = lib.filterAttrs (_: lib.isDerivation) (pkgs.callPackage "${inputs.hermes-agent}/nix/pm-packages.nix" {
          # Hermes patches 0.19.2; nixpkgs' default is older and its unstable version already includes the patch.
          patchelf = pkgs.patchelf.overrideAttrs {
            version = "0.19.2";
            src = pkgs.fetchurl {
              url = "https://github.com/NixOS/patchelf/releases/download/0.19.2/patchelf-0.19.2.tar.bz2";
              hash = "sha256-1K2aTlxongkRnOLzCpSw6LT5jHhZASPqIWZeNMaSiAE=";
            };
          };
        });
      };
      honchoPlugin = pkgs.fetchFromGitHub {
        name = "hermes-plugin-honcho";
        owner = "plastic-labs";
        repo = "honcho";
        rev = "7dd3702933d5cc1ce1f0a44bba6525cc61ee6e16";
        rootDir = "hermes-plugin-honcho";
        hash = "sha256-/9cirxS0ruMwVamHcY0bRSL/eCGcAOyPt+AuErgMwF0=";
      };
      honchoSdk = hermesPackage.python.pkgs.buildPythonPackage {
        pname = "honcho-ai";
        version = "2.8.0";
        format = "wheel";

        src = pkgs.fetchPypi {
          pname = "honcho_ai";
          version = "2.8.0";
          format = "wheel";
          python = "py3";
          dist = "py3";
          hash = "sha256-dL+IWz2GwRG2pXTmldULhhoIDiDxC+7P5gM27s/ZI34=";
        };

        # Use Hermes's httpx and pydantic without propagating duplicate packages.
        buildInputs = [hermesPackage.hermesVenv];
        pythonImportsCheck = ["honcho"];

        meta = {
          description = "Python SDK for Honcho conversational memory";
          homepage = "https://github.com/plastic-labs/honcho";
          license = lib.licenses.asl20;
        };
      };
      profilePath = lib.concatStringsSep ":" [
        "/etc/profiles/per-user/${config.home.username}/bin"
        "${config.home.homeDirectory}/.nix-profile/bin"
        "/run/current-system/sw/bin"
        "${config.home.homeDirectory}/.local/bin"
      ];
      servicePath = lib.makeBinPath ([
          config.programs.hermes-agent.package
          pkgs.bash
          pkgs.coreutils
          pkgs.git
        ]
        ++ config.services.hermes-agent.extraPackages);
    in {
      imports = [
        inputs.hermes-agent.homeManagerModules.default
        inputs.sops-nix.homeManagerModules.sops
      ];

      sops = {
        age.sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];

        secrets.hermes = {
          key = "env";
          sopsFile = self + "/secrets/hermes.yaml";
        };
      };

      programs.hermes-agent = {
        enable = true;
        package = hermesPackage;
      };

      # The memory-provider loader requires the directory name to match the provider.
      home.file.honcho-plugin = {
        target = "${config.services.hermes-agent.hermesHome}/plugins/honcho";
        source = honchoPlugin;
      };

      systemd.user.services = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        hermes-agent = lib.mkIf config.services.hermes-agent.gateway.enable {
          Service.Environment = lib.mkAfter ["PATH=${servicePath}:${profilePath}"];
        };
        hermes-backend = lib.mkIf (config.services.hermes-agent.backend.mode != "none") {
          Service.Environment = lib.mkAfter ["PATH=${servicePath}:${profilePath}"];
        };
      };

      services.hermes-agent = {
        enable = true;
        environmentFiles = [config.sops.secrets.hermes.path];
        gateway.enable = true;
        package =
          (hermesPackage.override {
            extraPythonPackages = [honchoSdk];
          }).overrideAttrs (old: {
            # The packaged Python tree omits the TUI's gateway bootstrap script.
            postInstall =
              (old.postInstall or "")
              + ''
                wrapProgram "$out/bin/hermes" \
                  --set HERMES_PYTHON_SRC_ROOT ${inputs.hermes-agent}
              '';
          });

        mcpServers =
          lib.recursiveUpdate (lib.mapAttrs (name: server:
            lib.intersectAttrs {
              command = null;
              args = null;
              env = null;
              url = null;
              headers = null;
              enabled = null;
            } (lib.hm.mcp.transformMcpServer {
              inherit server;
              extraTransforms = [(lib.hm.mcp.wrapEnvFilesCommand {inherit pkgs name;})];
            }))
          config.programs.mcp.servers) {
            # Hermes filters display variables from the MCP subprocess environment.
            chrome-devtools.env.WAYLAND_DISPLAY = "\${WAYLAND_DISPLAY}";

            linear.auth = "oauth";
            todoist.auth = "oauth";
          };

        backend = {
          mode = "dashboard";
          port = 9119;
        };

        settings = {
          browser.cloud_provider = "browserbase";
          display.interface = "tui";
          mcp_servers.todoist.trust = "full";
          memory.provider = "honcho";
          model = {
            default = "gpt-6.1-sol";
            provider = "openai-codex";
          };
          model_catalog.excluded_providers = ["nous" "openrouter"];
          plugins.enabled = ["honcho"];
          providers.kanto = {
            api = "https://openwebui.narwhal-snapper.ts.net/api";
            key_cmd = "${pkgs.coreutils}/bin/cat ${lib.escapeShellArg config.sops.secrets.openwebui.path}";
            transport = "chat_completions";
            default_model = "Qwen3.8-Flash-Next-Halogen";
            models = {
              "Qwen3.8-Flash-Next-Halogen".context_length = 262144;
              # Compatibility alias for Halogen; kept for existing chats.
              "Qwen3.8-Flash-Next-Strata".context_length = 262144;
              "Qwen3.8-27B-DFlash-GGUF".context_length = 65536;
              "Qwen3.6-35B-A3B-MTP-GGUF".context_length = 65536;
              "Muse-Glimmer-30B-GGUF".context_length = 65536;
            };
          };
          stt = {
            enabled = true;
            local.model = "base";
            openai.model = "whisper-1";
            provider = "openai";
          };
          tts = {
            elevenlabs = {
              model_id = "eleven_flash_v2_5";
              voice_id = "EST9Ui6982FZPSi7gCHi";
            };
            provider = "elevenlabs";
          };
          web.backend = "firecrawl";
        };
      };
    };
  };
}
