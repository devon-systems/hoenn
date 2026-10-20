_: {
  flake.homeModules.aly = {self, ...}: {
    imports = [self.homeModules.chatgpt];

    programs.home-manager.enable = true;
  };
}
