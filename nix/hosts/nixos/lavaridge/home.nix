{inputs, ...}: {
  flake.nixosModules.lavaridge = {self, ...}: {
    imports = [inputs.home-manager.nixosModules.home-manager];

    home-manager = {
      backupFileExtension = "backup";
      extraSpecialArgs = {inherit self;};
      useGlobalPkgs = true;
      useUserPackages = true;

      users.aly = {lib, ...}: {
        home = {
          homeDirectory = "/home/aly";
          stateVersion = "26.05";
          username = "aly";
        };

        imports = [
          self.homeModules.aly
          self.homeModules.appherder
          self.homeModules.chatgpt
          self.homeModules.claude-desktop
          self.homeModules.signal-desktop
          self.homeModules.slack
          self.homeModules.t3code
          self.homeModules.t3codeCli
          self.homeModules.ghostty
          self.homeModules.hermesAgent
          self.homeModules.himalaya
          self.homeModules.opencodeDesktop
          self.homeModules.switchyard
          self.homeModules.vesktop
          self.homeModules.vicinae
          self.homeModules.vscode
          self.homeModules.zed-editor
        ];

        services.hermes-agent = {
          backend.mode = lib.mkForce "none";
          # The shared messaging credentials already serve the existing gateway.
          gateway.enable = lib.mkForce false;
          settings.providers.lavaridge = {
            api = "http://127.0.0.1:13305/api/v1";
            transport = "chat_completions";
            default_model = "Qwen3.8-Flash-Next-Strata";
            models."Qwen3.8-Flash-Next-Strata".context_length = 65536;
          };
        };
      };
    };
  };
}
