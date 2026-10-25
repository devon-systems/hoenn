{lib, ...}: {
  flake.systemModules.systemManager = {
    config,
    pkgs,
    ...
  }: {
    # Newer Nixpkgs systemd helpers read this option; system-manager lacks it.
    options.systemd.defaultPath = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [pkgs.coreutils pkgs.findutils pkgs.gnugrep pkgs.gnused config.systemd.package];
      description = "Packages appended to the PATH of system-manager services.";
    };

    config = {
      environment.etc."environment.d/10-system-manager.conf".text = lib.mkForce ''
        PATH=/run/system-manager/sw/bin:/usr/local/bin:/usr/bin
        XDG_DATA_DIRS=/run/system-manager/sw/share:/usr/local/share:/usr/share
      '';

      system-manager.allowAnyDistro = true;
    };
  };
}
