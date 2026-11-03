_: {
  flake.nixosModules.petalburg = {pkgs, ...}: {
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
  };
}
