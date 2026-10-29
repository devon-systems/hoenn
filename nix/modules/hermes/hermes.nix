{inputs, ...}: {
  flake = {
    homeModules.hermesAgent = {
      config,
      lib,
      pkgs,
      self,
      ...
    }: let
      hermesPackage = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
      honchoPlugin = pkgs.fetchFromGitHub {
        name = "hermes-plugin-honcho";
        owner = "plastic-labs";
        repo = "honcho";
        rev = "e2d2aba182862deeb846e5cd4a30a41bce0ed82a";
        rootDir = "hermes-plugin-honcho";
        hash = "sha256-Lg17/7BPmqS2znsCAM/h2X8wrqYrIhNto+8eok5AgQA=";
      };
      honchoSdk = hermesPackage.python.pkgs.buildPythonPackage {
        pname = "honcho-ai";
        version = "2.2.0";
        format = "wheel";

        src = pkgs.fetchPypi {
          pname = "honcho_ai";
          version = "2.2.0";
          format = "wheel";
          python = "py3";
          dist = "py3";
          hash = "sha256-MvCYpMi8/kKI8JlN2rC8UqaNyHBp0PLOLIdY7ioXYfI=";
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

      programs.hermes-agent.enable = true;

      # The memory-provider loader requires the directory name to match the provider.
      home.file.honcho-plugin = {
        target = "${config.services.hermes-agent.hermesHome}/plugins/honcho";
        source = honchoPlugin;
      };

      systemd.user.services = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        hermes-agent.Service.Environment = lib.mkAfter ["PATH=${servicePath}:${profilePath}"];
        hermes-backend.Service.Environment = lib.mkAfter ["PATH=${servicePath}:${profilePath}"];
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
            default_model = "Qwen3.8-Flash-Next-Strata";
            models = {
              "Qwen3.8-Flash-Next-Strata".context_length = 262144;
              "qwen3.8:latest".context_length = 65536;
              "qwen3.6:35b-a3b-mtp-q4_K_M".context_length = 65536;
              "muse-glimmer:latest".context_length = 65536;
              "gemma4:latest".context_length = 65536;
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

    nixosModules.hermesWebui = {
      config,
      lib,
      ...
    }: {
      imports = [inputs.hermes-webui.nixosModules.default];

      systemd.services.hermes-webui = {
        serviceConfig.WorkingDirectory = "/home/aly";
        environment.PATH = lib.mkForce (lib.concatStringsSep ":" [
          (lib.makeBinPath config.systemd.services.hermes-webui.path)
          "/etc/profiles/per-user/aly/bin"
          "/home/aly/.nix-profile/bin"
          "/run/current-system/sw/bin"
          "/home/aly/.local/bin"
        ]);
      };

      services.hermes-webui = {
        enable = true;
        group = "aly";
        hermesHome = "/home/aly/.hermes";
        stateDir = "/home/aly/.hermes/webui";
        user = "aly";

        agent.package = config.home-manager.users.aly.programs.hermes-agent.package;
      };
    };
  };
}
