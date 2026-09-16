{inputs, ...}: {
  flake.nixosModules.mauville = {self, ...}: {
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
          self.homeModules.ghostty
          self.homeModules.zed-editor
          self.homeModules.vscode
          self.homeModules.opencodeDesktop
        ];
      };
    };
  };
}
