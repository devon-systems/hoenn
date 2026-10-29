{inputs, ...}: {
  flake.homeModules.t3codeServer = {
    config,
    lib,
    pkgs,
    ...
  }: let
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.t3code;
    servicePath = lib.concatStringsSep ":" [
      (lib.makeBinPath [pkgs.bash pkgs.coreutils pkgs.git pkgs.tailscale])
      "/etc/profiles/per-user/${config.home.username}/bin"
      "${config.home.homeDirectory}/.nix-profile/bin"
      "/run/current-system/sw/bin"
      "${config.home.homeDirectory}/.local/bin"
    ];
  in {
    home.packages = [package];

    systemd.user.services.t3code = {
      Unit = {
        Description = "T3 Code backend";
        After = ["network.target"];
        StartLimitIntervalSec = 0;
      };

      Service = {
        ExecStart = "${package}/bin/t3 serve --host 127.0.0.1 --port 3773";
        WorkingDirectory = config.home.homeDirectory;
        Environment = ["PATH=${servicePath}"];
        Restart = "on-failure";
        RestartSec = 5;
        KillMode = "mixed";
        TimeoutStopSec = 30;
        UMask = "0077";
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
