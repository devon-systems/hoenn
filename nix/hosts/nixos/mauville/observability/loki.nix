_: {
  flake.nixosModules.mauville = {
    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server = {
          http_listen_port = 3030;
          grpc_listen_address = "127.0.0.1";
          grpc_listen_port = 9096;
        };
        common = {
          path_prefix = "/var/lib/loki";
          instance_addr = "127.0.0.1";
          replication_factor = 1;
          ring.kvstore.store = "inmemory";
          storage.filesystem = {
            chunks_directory = "/var/lib/loki/chunks";
            rules_directory = "/var/lib/loki/rules";
          };
        };
        compactor = {
          working_directory = "/var/lib/loki/compactor";
          retention_enabled = true;
          delete_request_store = "filesystem";
        };
        limits_config.retention_period = "14d";
        schema_config.configs = [
          {
            from = "2024-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
        analytics.reporting_enabled = false;
      };
    };
  };
}
