{inputs, ...}: {
  flake.nixosModules.petalburg = {config, ...}: {
    users.users.aly.linger = true;

    home-manager.users.aly = {
      config,
      lib,
      pkgs,
      ...
    }: {
      # The background server owns ~/.t3; the desktop pairs with it separately.
      programs.t3code.package = lib.mkForce (pkgs.symlinkJoin {
        name = "t3code-desktop-petalburg";
        paths = [inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.t3code-desktop];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram "$out/bin/t3code-desktop" \
            --set T3CODE_HOME ${lib.escapeShellArg "${config.home.homeDirectory}/.t3-desktop"}
        '';
      });

      xdg.desktopEntries."com.t3tools.T3Code" = {
        name = "T3 Code (Beta)";
        exec = "${config.programs.t3code.package}/bin/t3code-desktop %U";
        noDisplay = true;
        mimeType = ["x-scheme-handler/t3code"];
      };
    };

    # Keep the existing Tailscale Serve endpoints on 443 and 8788.
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
