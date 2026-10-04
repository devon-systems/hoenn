{inputs, ...}: {
  flake = {
    homeModules.hermesAgent = {
      config,
      lib,
      pkgs,
      self,
      ...
    }: let
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

      # Extend the packaged runtime PATH without sourcing interactive shell files.
      systemd.user.services = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        hermes-agent.Service.Environment = lib.mkAfter ["PATH=${servicePath}:${profilePath}"];
        hermes-backend.Service.Environment = lib.mkAfter ["PATH=${servicePath}:${profilePath}"];
      };

      services.hermes-agent = {
        enable = true;
        environmentFiles = [config.sops.secrets.hermes.path];
        gateway.enable = true;

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
          };

        backend = {
          mode = "dashboard";
          port = 9119;
        };

        settings = {
          browser.cloud_provider = "browserbase";
          display.interface = "tui";
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
      pkgs,
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

        agent.package =
          inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
    };
  };
}
