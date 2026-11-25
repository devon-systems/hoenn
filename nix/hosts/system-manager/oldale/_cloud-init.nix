{
  lib,
  self,
}: let
  keysDirectory = self + "/keys";
  authorizedKeys = lib.pipe (builtins.readDir keysDirectory) [
    builtins.attrNames
    (lib.filter (name: lib.hasPrefix "aly_" name && lib.hasSuffix ".pub" name))
    (map (name: lib.trim (builtins.readFile (keysDirectory + "/${name}"))))
  ];
in {
  hostname = "oldale";
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
  apt.sources.tailscale = {
    source = "deb [signed-by=$KEY_FILE] https://pkgs.tailscale.com/stable/ubuntu stonking main";
    key = builtins.readFile ./tailscale.asc;
  };

  packages = [
    "ca-certificates"
    "curl"
    "git"
    "sudo"
    "ufw"
    "docker.io"
    "openssh-server"
    "tailscale"
    "unattended-upgrades"
    "build-essential"
    "pkg-config"
  ];

  write_files = [
    {
      path = "/usr/local/sbin/oldale-bootstrap";
      permissions = "0755";
      content = builtins.readFile ./bootstrap.sh;
    }
  ];
  runcmd = [
    ["ufw" "default" "deny" "incoming"]
    ["ufw" "allow" "in" "on" "tailscale0" "to" "any" "port" "22" "proto" "tcp"]
    ["ufw" "allow" "in" "on" "tailscale0" "to" "any" "port" "3773" "proto" "tcp"]
    ["ufw" "allow" "41641/udp"]
    ["ufw" "--force" "enable"]
  ];
}
