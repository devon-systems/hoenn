_: {
  flake.nixosModules.mauville = {
    services.prometheus = {
      enable = true;
      port = 3020;
      retentionTime = "30d";
      extraFlags = ["--web.enable-remote-write-receiver"];
      globalConfig = {
        scrape_interval = "60s";
        evaluation_interval = "60s";
      };
      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = ["127.0.0.1:3020"];
              labels.host = "mauville";
            }
          ];
        }
        {
          job_name = "loki";
          static_configs = [
            {
              targets = ["127.0.0.1:3030"];
              labels.host = "mauville";
            }
          ];
        }
      ];
    };
  };
}
