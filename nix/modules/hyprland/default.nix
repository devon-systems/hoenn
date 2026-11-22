_: let
  mkHyprlandModule = packageName: {
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
    ];

    programs.hyprland = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.${packageName};
    };

    services.gvfs.enable = true;

    xdg.icons.fallbackCursorThemes = ["Adwaita"];
    programs.noctalia = {
      enable = true;
      recommendedServices.enable = true;
      systemd.enable = true;
    };

    services.displayManager.noctalia-greeter.enable = true;
  };
in {
  flake = {
    nixosModules.hyprland = mkHyprlandModule "hyprland";
    nixosModules.hyprlandStacking = mkHyprlandModule "hyprland-stacking";
  };
}
