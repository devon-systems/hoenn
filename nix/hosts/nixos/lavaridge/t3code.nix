{self, ...}: {
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
        paths = [self.packages.${pkgs.stdenv.hostPlatform.system}.t3code-desktop];
        nativeBuildInputs = [pkgs.makeWrapper];

        postBuild = ''
          wrapProgram "$out/bin/t3code-desktop" \
            --set T3CODE_HOME ${lib.escapeShellArg "${config.home.homeDirectory}/.t3-desktop"}
        '';
      });
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
