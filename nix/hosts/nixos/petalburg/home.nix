{inputs, ...}: {
  flake.nixosModules.petalburg = {self, ...}: {
    imports = [inputs.home-manager.nixosModules.home-manager];

    home-manager = {
      backupFileExtension = "backup";
      extraSpecialArgs = {inherit self;};
      useGlobalPkgs = true;
      useUserPackages = true;

      users.aly = {config, ...}: {
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
          self.homeModules.t3codeServer
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

        sops.secrets.petalburgHermes = {
          key = "env";
          sopsFile = self + "/secrets/petalburg-hermes.yaml";
        };

        services.hermes-agent = {
          environmentFiles = [config.sops.secrets.petalburgHermes.path];
          settings.dashboard.public_url = "https://petalburg.narwhal-snapper.ts.net";
        };
      };
    };
  };
}
