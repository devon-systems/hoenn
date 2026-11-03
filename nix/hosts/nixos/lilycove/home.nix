{inputs, ...}: {
  flake.nixosModules.lilycove = {self, ...}: {
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
          self.homeModules.aly-desktop
          self.homeModules.appherder
          self.homeModules.signal-desktop
          self.homeModules.slack
          self.homeModules.t3code
          self.homeModules.himalaya
          self.homeModules.switchyard
          self.homeModules.vesktop
          self.homeModules.vicinae
          self.homeModules.vscode
          self.homeModules.zed-editor
        ];
      };
    };
  };
}
