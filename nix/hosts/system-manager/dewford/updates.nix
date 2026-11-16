_: {
  flake.systemModules.dewford = {
    environment.etc."apt/apt.conf.d/90-hoenn-upgrades".text = ''
      APT::Periodic::Update-Package-Lists "1";
      APT::Periodic::Unattended-Upgrade "1";
      Unattended-Upgrade::Automatic-Reboot "false";
    '';

    systemd.targets.system-manager.wants = [
      "apt-daily.timer"
      "apt-daily-upgrade.timer"
    ];
  };
}
