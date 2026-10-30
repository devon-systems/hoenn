{inputs, ...}: {
  flake.nixosModules.lavaridge = {
    config,
    pkgs,
    ...
  }: {
    users.users.aly.linger = true;

    programs.nix-ld.libraries = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      dbus
      expat
      glib
      libgbm
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      nspr
      nss
      systemd
    ];

    home-manager.users.aly = {
      config,
      lib,
      pkgs,
      ...
    }: {
      programs.t3code.package = lib.mkForce (pkgs.symlinkJoin {
        name = "t3code-desktop-lavaridge";
        paths = [inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.t3code-desktop];
        nativeBuildInputs = [pkgs.makeWrapper];

        postBuild = ''
          wrapProgram "$out/bin/t3code-desktop" \
            --set T3CODE_HOME ${lib.escapeShellArg "${config.home.homeDirectory}/.t3-desktop"}
        '';
      });

      systemd.user.services.t3code = {
        Unit.Description = "T3 Code local host server";
        Service = {
          ExecStart = "${lib.getExe inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.t3code} start --host 127.0.0.1 --port 3773 --no-browser --base-dir ${config.home.homeDirectory}/.t3";
          WorkingDirectory = config.home.homeDirectory;
          Environment = "PATH=/etc/profiles/per-user/aly/bin:/run/current-system/sw/bin:%h/.local/bin";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = ["default.target"];
      };

      xdg.desktopEntries."com.t3tools.T3Code" = {
        name = "T3 Code (Beta)";
        exec = "${config.programs.t3code.package}/bin/t3code-desktop %U";
        noDisplay = true;
        mimeType = ["x-scheme-handler/t3code"];
      };
    };

    systemd.services.t3code-tailscale = {
      description = "Tailscale HTTPS access to T3 Code";
      wantedBy = ["multi-user.target"];
      after = ["tailscaled.service" "network-online.target"];
      wants = ["network-online.target"];
      requires = ["tailscaled.service"];
      unitConfig.StartLimitIntervalSec = 0;

      serviceConfig = {
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --https=8443 --yes http://127.0.0.1:3773";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
