{inputs, ...}: {
  flake.nixosModules.rustboro = {self, ...}: {
    imports = [inputs.home-manager.nixosModules.home-manager];

    home-manager = {
      backupFileExtension = "backup";
      extraSpecialArgs = {inherit self;};
      useGlobalPkgs = true;
      useUserPackages = true;

      users.aly = {
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
          self.homeModules.t3code
          self.homeModules.ghostty
          self.homeModules.himalaya
          self.homeModules.vesktop
          self.homeModules.vicinae
          self.homeModules.zed-editor
          self.homeModules.vscode
          self.homeModules.opencodeDesktop
          self.homeModules.switchyard
        ];
      };
    };
  };
}
