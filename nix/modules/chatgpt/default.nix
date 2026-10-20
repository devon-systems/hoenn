_: {
  flake.homeModules.chatgpt = {pkgs, ...}: {
    home.packages = [pkgs.chatgpt];
  };
}
