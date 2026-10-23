{
  hostName,
  isLinux,
  cominPort ? null,
  server ? "mauville.hoenn",
}: let
  os =
    if isLinux
    then "linux"
    else "darwin";
  collectors =
    if isLinux
    then ''
      enable_collectors = ["systemd", "powersupplyclass", "textfile"]
      textfile {
        directory = "/var/lib/hoenn-metrics/*"
      }
    ''
    else ''disable_collectors = ["thermal"]'';
in
  ''
    prometheus.exporter.unix "desktop" {
      ${collectors}
    }

    discovery.relabel "desktop" {
      targets = prometheus.exporter.unix.desktop.targets
      rule {
        target_label = "job"
        replacement  = "node"
      }
      rule {
        target_label = "instance"
        replacement  = "${hostName}"
      }
      rule {
        target_label = "host"
        replacement  = "${hostName}"
      }
      rule {
        target_label = "os"
        replacement  = "${os}"
      }
    }

    prometheus.scrape "desktop" {
      targets         = discovery.relabel.desktop.output
      job_name        = "node"
      scrape_interval = "60s"
      scrape_timeout  = "20s"
      forward_to      = [prometheus.remote_write.mauville.receiver]
    }

    prometheus.remote_write "mauville" {
      endpoint {
        url = "http://${server}:3020/api/v1/write"
        queue_config {
          max_shards = 2
        }
      }
      wal {
        max_keepalive_time = "24h"
      }
    }

    loki.process "redact" {
      forward_to = [loki.write.mauville.receiver]
      stage.replace {
        expression = `(?i)\b(?:x-plex-token|plexonlinetoken|access_token|refresh_token|api[_-]?key|password|client_secret|authorization)["' ]*(?:[:=]|%3[dDaA])\s*"((?:\\.|[^"\\])*)"`
        replace = "[REDACTED]"
      }
      stage.replace {
        expression = `(?i)\b(?:x-plex-token|plexonlinetoken|access_token|refresh_token|api[_-]?key|password|client_secret|authorization)["' ]*(?:[:=]|%3[dDaA])\s*'((?:\\.|[^'\\])*)'`
        replace = "[REDACTED]"
      }
      stage.replace {
        expression = `(?i)\b(?:x-plex-token|plexonlinetoken|access_token|refresh_token|api[_-]?key|password|client_secret|authorization)["' ]*(?:[:=]|%3[dDaA])\s*(?:bearer\s+|basic\s+)?([^&\s"'<>]+)`
        replace = "[REDACTED]"
      }
    }

    loki.write "mauville" {
      endpoint {
        url                 = "http://${server}:3030/loki/api/v1/push"
        max_backoff_retries = 20
      }
    }
  ''
  + (
    if cominPort != null
    then ''
      prometheus.scrape "comin" {
        targets = [{
          __address__ = "127.0.0.1:${toString cominPort}",
          instance    = "${hostName}",
          host        = "${hostName}",
          cluster     = "hoenn",
          os          = "${os}",
        }]
        job_name        = "comin"
        scrape_interval = "60s"
        forward_to      = [prometheus.remote_write.mauville.receiver]
      }
    ''
    else ""
  )
  + (
    if isLinux
    then ''
      prometheus.scrape "smartctl" {
        targets = [{
          __address__ = "127.0.0.1:9633",
          instance    = "${hostName}",
          host        = "${hostName}",
          os          = "linux",
        }]
        job_name        = "smartctl"
        scrape_interval = "60s"
        scrape_timeout  = "30s"
        forward_to      = [prometheus.remote_write.mauville.receiver]
      }

      loki.relabel "journal" {
        forward_to = []
        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }
        rule {
          source_labels = ["__journal__systemd_unit"]
          regex         = "comin[.]service"
          target_label  = "service"
          replacement   = "comin"
        }
        rule {
          source_labels = ["__journal__systemd_user_unit"]
          target_label  = "user_unit"
        }
        rule {
          source_labels = ["__journal_priority_keyword"]
          target_label  = "level"
        }
      }

      loki.source.journal "desktop" {
        forward_to    = [loki.process.redact.receiver]
        relabel_rules = loki.relabel.journal.rules
        max_age       = "720h"
        labels        = {
          job  = "systemd-journal",
          host = "${hostName}",
          os   = "linux",
        }
      }
    ''
    else
      ''
        local.file_match "system" {
          path_targets = [
            {__path__ = "/var/log/system.log", job = "system-log", host = "${hostName}", os = "darwin"},
            {__path__ = "/var/log/nix-darwin-upgrade.log", job = "system-log", host = "${hostName}", os = "darwin"},
          ]
        }

        loki.source.file "system" {
          targets    = local.file_match.system.targets
          forward_to = [loki.process.redact.receiver]
        }
      ''
      + (
        if cominPort != null
        then ''
          local.file_match "comin" {
            path_targets = [{
              __path__ = "/var/log/comin.log",
              job      = "comin",
              service  = "comin",
              host     = "${hostName}",
              os       = "darwin",
            }]
          }

          loki.source.file "comin" {
            targets    = local.file_match.comin.targets
            forward_to = [loki.process.redact.receiver]
          }
        ''
        else ""
      )
  )
