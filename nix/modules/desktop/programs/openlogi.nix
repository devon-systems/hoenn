{
  flake = {
    nixosModules.desktop = {
      config,
      lib,
      ...
    }: {
      programs.openlogi.enable = true;

      systemd.user.services.openlogi-agent = {
        description = "OpenLogi background agent";
        wantedBy = ["graphical-session.target"];
        after = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        serviceConfig = {
          ExecStart = lib.getExe' config.programs.openlogi.package "openlogi-agent";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };

    darwinModules.desktop = {
      homebrew.casks = ["openlogi"];
    };
  };
}
