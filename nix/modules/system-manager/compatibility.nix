{lib, ...}: {
  flake.systemModules.systemManager = {
    environment.etc."environment.d/10-system-manager.conf".text = lib.mkForce ''
      PATH=/run/system-manager/sw/bin:/usr/local/bin:/usr/bin
      XDG_DATA_DIRS=/run/system-manager/sw/share:/usr/local/share:/usr/share
    '';

    system-manager.allowAnyDistro = true;
  };
}
