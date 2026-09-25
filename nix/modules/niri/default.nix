_: let
  mkNiriModule = packageName: {
    pkgs,
    self,
    ...
  }: {
    environment.systemPackages = [
      pkgs.adwaita-icon-theme
      pkgs.ddcutil
      pkgs.file-roller
      pkgs.foliate
      pkgs.ghostty
      pkgs.gnome-disk-utility
      pkgs.gnome-text-editor
      pkgs.loupe
      pkgs.morewaita-icon-theme
      pkgs.nautilus
      pkgs.papers
      pkgs.vicinae
      pkgs.xwayland-satellite
    ];

    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.${packageName};
      useNautilus = true;
    };

    services = {
      gvfs.enable = true;
      iio-niri.enable = true;
    };

    xdg.icons.fallbackCursorThemes = ["Adwaita"];
  };
in {
  flake = {
    nixosModules.niri = {...}: {
      imports = [
        (mkNiriModule "niri")
      ];

      programs.noctalia = {
        enable = true;
        recommendedServices.enable = true;
        systemd.enable = true;
      };

      services.displayManager.noctalia-greeter.enable = true;
    };

    nixosModules.niriDms = {pkgs, ...}: {
      imports = [
        (mkNiriModule "niri-dms")
      ];

      environment.systemPackages = [
        pkgs.satty
      ];

      programs.dms-shell = {
        enable = true;
        systemd.enable = true;
      };

      services.displayManager.dms-greeter = {
        enable = true;
        compositor.name = "niri";
      };
    };

    homeModules.niri = {
      pkgs,
      self,
      ...
    }: {
      wayland.windowManager.niri = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.niri;
      };
    };
  };
}
