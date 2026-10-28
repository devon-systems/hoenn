_: {
  flake.nixosModules.docker = {pkgs, ...}: {
    virtualisation.docker = {
      enable = true;

      autoPrune = {
        enable = true;
        dates = "weekly";
        randomizedDelaySec = "1h";
        persistent = true;
        # Keep volumes, which may contain persistent application data.
        flags = ["--all" "--filter" "until=168h"];
      };
    };

    environment.systemPackages = [pkgs.docker-compose];
  };
}
