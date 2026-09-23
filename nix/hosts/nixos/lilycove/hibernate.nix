_: {
  flake.nixosModules.lilycove = {
    boot = {
      resumeDevice = "/dev/mapper/cryptroot";
      kernelParams = ["resume_offset=3941632"];
    };

    systemd.sleep.settings.Sleep.HibernateMode = "shutdown";
  };
}
