_: {
  flake.homeModules.aly = {pkgs, ...}: {
    programs.rbw = {
      enable = true;

      settings = {
        base_url = "https://vault.cute.haus";
        email = "alyraffauf@fastmail.com";
        pinentry = pkgs.pinentry-curses;
      };
    };
  };
}
