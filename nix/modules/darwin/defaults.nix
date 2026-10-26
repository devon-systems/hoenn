_: {
  flake.darwinModules.darwin = {
    system.defaults = {
      LaunchServices.LSQuarantine = false;

      CustomUserPreferences = {
        NSGlobalDomain.WebKitDeveloperExtras = true;

        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };

        "com.apple.screencapture" = {
          location = "~/Pictures/screenshots";
          type = "png";
        };

        # Give each monitor its own Spaces.
        "com.apple.spaces"."spans-displays" = 0;
      };
    };
  };
}
