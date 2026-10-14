_: {
  flake.homeModules.vesktop = {
    programs.vesktop = {
      enable = true;
      mutableSettings = true;

      vencord = {
        mutableSettings = true;

        settings = {
          autoUpdate = true;
          autoUpdateNotification = false;
          disableMinSize = true;
          notifyAboutUpdates = false;

          plugins = {
            AlwaysTrust.enabled = true;
            BetterFolders = true;
            BlurNSFW.enabled = true;
            ClearURLs.enabled = true;
            FakeNitro.enabled = true;
            PinDMs.enabled = true;
            WebKeybinds.enabled = true;
            WebScreenShareFixes.enabled = true;
          };

          useQuickCss = true;
        };

        useSystem = true;
      };

      settings = {
        arRPC = true;
        checkUpdates = false;
        enableSplashScreen = false;
      };
    };
  };
}
