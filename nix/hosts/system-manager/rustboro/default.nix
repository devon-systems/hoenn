{
  inputs,
  lib,
  self,
  ...
}: {
  options.flake.systemModules.rustboro = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.flake.systemModules.rustboro = {pkgs, ...}: {
    environment.etc = {
      "systemd/system-generators/zram-generator".source = "${pkgs.zram-generator}/lib/systemd/system-generators/zram-generator";
      "systemd/system/systemd-zram-setup@.service".source = "${pkgs.zram-generator}/lib/systemd/system/systemd-zram-setup@.service";
      "systemd/zram-generator.conf".text = ''
        [zram0]
        zram-size = min(ram / 2, 4096)
        swap-priority = 100
      '';
    };
  };

  config.flake.systemConfigs.rustboro = inputs.system-manager.lib.makeSystemConfig {
    modules = [
      inputs.home-manager.nixosModules.home-manager
      self.systemModules.systemManager
      self.systemModules.rustboro
    ];
  };

  config.blzrd.nodes.rustboro = {
    output = self.systemConfigs.rustboro;
    type = "system-manager";
    user = "root";
  };
}
