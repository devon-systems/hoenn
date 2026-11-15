{
  inputs,
  sharedPackageSets,
  ...
}: {
  flake.homeConfigurations."aly@dewford" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = sharedPackageSets.x86_64-linux;
    modules = [
      ({
        config,
        lib,
        pkgs,
        ...
      }: let
        t3code = inputs.dvnpkgs.packages.x86_64-linux.t3code;
      in {
        home = {
          username = "aly";
          homeDirectory = "/home/aly";
          stateVersion = "26.05";
          packages = with pkgs; [
            fd
            jq
            just
            ripgrep
            tmux
            t3code
          ];
        };

        targets.genericLinux.enable = true;
        programs = {
          home-manager.enable = true;
          bash.enable = true;
          fish.enable = true;
          neovim.enable = true;
          gh.enable = true;
          git = {
            enable = true;
            lfs.enable = true;
            settings = {
              user.name = "Aly Raffauf";
              user.email = "aly@aly.codes";
              init.defaultBranch = "main";
              pull.rebase = true;
              push.autoSetupRemote = true;
            };
          };
          direnv = {
            enable = true;
            nix-direnv.enable = true;
          };
          codex = {
            enable = true;
            package = inputs.llm-agents.packages.x86_64-linux.codex;
            mutableSettings = true;
            settings = {
              approval_policy = "never";
              default_permissions = ":danger-full-access";
              mcp_oauth_credentials_store = "file";
            };
          };
          claude-code = {
            enable = true;
            mutableSettings = true;
            settings = {
              permissions.defaultMode = "bypassPermissions";
              sandbox.enabled = false;
            };
          };
        };

        systemd.user.startServices = "sd-switch";
        systemd.user.services.t3code = {
          Unit.Description = "T3 Code server";
          Service = {
            ExecStart = "${lib.getExe t3code} serve --host 0.0.0.0 --port 3773 --lan --base-dir ${config.home.homeDirectory}/.t3";
            WorkingDirectory = config.home.homeDirectory;
            Environment = [
              "PATH=${config.home.profileDirectory}/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
            ];
            Restart = "on-failure";
            RestartSec = 5;
            KillMode = "mixed";
          };
          Install.WantedBy = ["default.target"];
        };
      })
    ];
  };
}
