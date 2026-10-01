{inputs, ...}: {
  flake = {
    nixosModules.zen = {pkgs, ...}: {
      environment.systemPackages = [
        (inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser.override {
          wrapFirefox = browser: options:
            pkgs.wrapFirefox browser (options
              // {
                extraPolicies.ExtensionSettings."{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
                  install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
                  installation_mode = "normal_installed";
                };
              });
        })
      ];
    };

    darwinModules.zen = {
      homebrew.casks = ["zen"];
    };
  };
}
