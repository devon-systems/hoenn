_: {
  flake.darwinModules.fallarbor = {
    # Determinate manages Nix; the built-in maintenance services require nix.enable.
    launchd.daemons.nix-maintenance = {
      script = ''
        set -eu
        export PATH=/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin
        printf '\nNix maintenance started: '
        date
        nix-collect-garbage --delete-older-than 3d
        nix-store --optimise
        printf 'Nix maintenance completed: '
        date
      '';
      serviceConfig = {
        StartCalendarInterval = {
          Hour = 3;
          Minute = 0;
        };
        Nice = 10;
        ProcessType = "Background";
        LowPriorityIO = true;
        StandardOutPath = "/var/log/hoenn-nix-maintenance.log";
        StandardErrorPath = "/var/log/hoenn-nix-maintenance.error.log";
      };
    };
  };
}
