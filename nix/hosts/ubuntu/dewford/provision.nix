{self, ...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    keysDirectory = self + "/keys";
    authorizedKeys = lib.pipe (builtins.readDir keysDirectory) [
      builtins.attrNames
      (lib.filter (name: lib.hasPrefix "aly_" name && lib.hasSuffix ".pub" name))
      (map (name: lib.trim (builtins.readFile (keysDirectory + "/${name}"))))
    ];
    cloudConfig = (pkgs.formats.yaml {}).generate "dewford-cloud-init.yaml" {
      hostname = "dewford";
      manage_etc_hosts = true;
      ssh_pwauth = false;
      disable_root = true;
      groups = ["docker"];
      users = [
        {
          name = "aly";
          uid = 1000;
          groups = ["sudo" "docker"];
          shell = "/bin/bash";
          sudo = "ALL=(ALL) NOPASSWD:ALL";
          lock_passwd = true;
          ssh_authorized_keys = authorizedKeys;
        }
      ];
      package_update = true;
      packages = ["ca-certificates" "curl" "git" "sudo" "xz-utils" "ufw" "docker.io" "openssh-server" "build-essential" "pkg-config"];
      write_files = [
        {
          path = "/usr/local/sbin/dewford-bootstrap";
          permissions = "0755";
          content = builtins.readFile ../../../../scripts/dewford-bootstrap.sh;
        }
      ];
      runcmd = [
        ["loginctl" "enable-linger" "aly"]
        ["systemctl" "enable" "--now" "docker.service"]
        ["systemctl" "enable" "--now" "ssh.service"]
        ["ufw" "default" "deny" "incoming"]
        ["ufw" "allow" "in" "on" "tailscale0" "to" "any" "port" "22" "proto" "tcp"]
        ["ufw" "allow" "in" "on" "tailscale0" "to" "any" "port" "3773" "proto" "tcp"]
        ["ufw" "allow" "41641/udp"]
        ["ufw" "--force" "enable"]
      ];
    };
  in {
    packages.dewford-create = pkgs.writeShellApplication {
      name = "dewford-create";
      runtimeInputs = [pkgs.incus.client];
      text = ''
        # Check access before interpreting an instance lookup failure as absence.
        incus query /1.0 >/dev/null
        if incus info dewford >/dev/null 2>&1; then
          echo 'Dewford already exists; refusing to replace it.' >&2
          exit 1
        fi
        incus init images:ubuntu/stonking/cloud dewford --vm --profile dewford \
          --config cloud-init.user-data="$(printf '#cloud-config\n'; cat ${cloudConfig})"
        incus start dewford
        echo 'Wait for the agent, then run: sudo incus exec dewford -- cloud-init status --wait'
        echo 'Bootstrap with: sudo incus exec dewford -- dewford-bootstrap'
      '';
    };
  };
}
