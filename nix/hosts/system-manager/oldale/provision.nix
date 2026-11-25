{self, ...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    cloudConfig = (pkgs.formats.yaml {}).generate "oldale-cloud-init.yaml" (
      import ./_cloud-init.nix {inherit lib self;}
    );
    authKeyFile = self.nixosConfigurations.petalburg.config.services.tailscale.authKeyFile;
    enroll = pkgs.writeShellApplication {
      name = "oldale-enroll";
      runtimeInputs = [pkgs.incus.client pkgs.jq pkgs.coreutils];
      text = ''
        incus query /1.0 >/dev/null
        for attempt in $(seq 1 60); do
          if incus exec oldale -- true 2>/dev/null; then
            break
          fi
          if [ "$attempt" -eq 60 ]; then
            echo 'Oldale guest agent did not become ready.' >&2
            exit 1
          fi
          sleep 2
        done
        incus exec oldale -- cloud-init status --wait
        incus exec oldale -- systemctl start tailscaled.service
        if incus exec oldale -- tailscale status --json | jq -e '.BackendState == "Running"' >/dev/null; then
          echo 'Oldale is already enrolled in Tailscale.'
          exit 0
        fi
        # Incus forwards stdin; the enrollment key never enters guest files or argv.
        incus exec oldale --mode non-interactive -- \
          tailscale up --auth-key=file:/dev/stdin --hostname=oldale --ssh --timeout=60s \
          < ${lib.escapeShellArg authKeyFile}
      '';
    };
  in {
    packages = {
      oldale-enroll = enroll;
      oldale-create = pkgs.writeShellApplication {
        name = "oldale-create";
        runtimeInputs = [pkgs.incus.client pkgs.coreutils];
        text = ''
          # Check access before interpreting an instance lookup failure as absence.
          incus query /1.0 >/dev/null
          if incus info oldale >/dev/null 2>&1; then
            echo 'Oldale already exists; refusing to replace it.' >&2
            exit 1
          fi
          incus init images:ubuntu/stonking/cloud oldale --vm --profile oldale \
            --config cloud-init.user-data="$(printf '#cloud-config\n'; cat ${cloudConfig})"
          incus start oldale
          ${lib.getExe enroll}
          echo 'Bootstrap with: sudo incus exec oldale -- oldale-bootstrap'
        '';
      };
    };
  };
}
