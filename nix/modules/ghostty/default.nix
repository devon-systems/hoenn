_: {
  flake.homeModules.ghostty = {
    pkgs,
    lib,
    ...
  }: {
    programs.ghostty = {
      enable = true;
      package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin pkgs.ghostty-bin;

      settings =
        {
          theme = "Catppuccin Frappe";
          notify-on-command-finish = "unfocused";
          tab-inherit-working-directory = false;
          window-inherit-working-directory = false;
          font-family = "CaskaydiaCove Nerd Font";
          background-blur = true;
          background-opacity = 0.8;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          window-theme = "ghostty";
          linux-cgroup = "always";
          keybind = ["ctrl+shift+backquote=toggle_tab_overview"];
          window-show-tab-bar = "never";
          window-decoration = false;
        };
    };
  };
}
