{inputs}: {
  config,
  lib,
  pkgs,
  ...
}: let
  upstream = import "${inputs.nix-darwin}/modules/system/launchd.nix" {inherit config lib pkgs;};
  activation = upstream.config.system.activationScripts.launchd.text;
  commands = [
    "launchctl unload '/Library/LaunchDaemons/com.github.nlewo.comin.plist' || true"
    "launchctl load -w '/Library/LaunchDaemons/com.github.nlewo.comin.plist'"
  ];
  # Comin passes --comin to activation and reloads itself after saving the
  # deployment result. Manual activations retain nix-darwin's normal reload.
  guardedCommands =
    map (command: ''
      if [[ "''${1:-}" != --comin ]]; then
        ${command}
      fi
    '')
    commands;
in
  upstream
  // {
    config = lib.mkMerge [
      upstream.config
      {
        system.activationScripts.launchd.text = lib.mkForce (
          assert lib.assertMsg (lib.all (command: lib.hasInfix command activation) commands) "Comin's launchd override must be updated for this nix-darwin version.";
            lib.replaceStrings commands guardedCommands activation
        );
      }
    ];
  }
