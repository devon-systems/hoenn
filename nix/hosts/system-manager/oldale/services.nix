_: {
  flake.systemModules.oldale = {
    # Start the distro-provided services without replacing their unit files.
    systemd.targets.system-manager.wants = [
      "docker.service"
      "ssh.service"
      "tailscaled.service"
    ];

    systemd.services.oldale-setup = {
      description = "Prepare Oldale's development user and Tailscale SSH";
      wantedBy = ["system-manager.target"];
      requires = ["tailscaled.service"];
      after = ["tailscaled.service"];
      before = ["home-manager-aly.service"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        /usr/bin/loginctl enable-linger aly
        /usr/bin/tailscale set --ssh
      '';
    };

    systemd.services.oldale-shell = {
      description = "Select the Home Manager Fish login shell";
      wantedBy = ["system-manager.target"];
      requires = ["home-manager-aly.service"];
      after = ["home-manager-aly.service"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        shell=/home/aly/.nix-profile/bin/fish
        test -x "$shell"
        if ! /usr/bin/grep -Fxq "$shell" /etc/shells; then
          printf '%s\n' "$shell" >> /etc/shells
        fi
        /usr/sbin/usermod --shell "$shell" aly
      '';
    };
  };
}
