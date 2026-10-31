_: {
  flake.nixosModules.lavaridge.services.tuned = {
    profiles.lavaridge-performance = {
      main = {
        summary = "Performance mode for shared CPU and GPU workloads";
        include = "balanced";
      };
      cpu = {
        governor = "performance";
        energy_performance_preference = "performance";
      };
      acpi.platform_profile = "performance";
    };

    ppdSettings = {
      main.default = "performance";
      profiles = {
        balanced = "balanced";
        performance = "lavaridge-performance";
        power-saver = "powersave";
      };
    };
  };
}
