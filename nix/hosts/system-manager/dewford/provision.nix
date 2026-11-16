{self, ...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    cloudConfig = (pkgs.formats.yaml {}).generate "dewford-cloud-init.yaml" (
      import ./_cloud-init.nix {inherit lib self;}
    );
    authKeyFile = self.nixosConfigurations.petalburg.config.services.tailscale.authKeyFile;
    enroll = pkgs.writeShellApplication {
      name = "dewford-enroll";
      runtimeInputs = [pkgs.incus.client pkgs.jq pkgs.coreutils];
      text = ''
        incus query /1.0 >/dev/null
        for attempt in $(seq 1 60); do
          if incus exec dewford -- true 2>/dev/null; then
            break
          fi
          if [ "$attempt" -eq 60 ]; then
            echo 'Dewford guest agent did not become ready.' >&2
            exit 1
          fi
          sleep 2
        done
        incus exec dewford -- cloud-init status --wait
        incus exec dewford -- systemctl start tailscaled.service
        if incus exec dewford -- tailscale status --json | jq -e '.BackendState == "Running"' >/dev/null; then
          echo 'Dewford is already enrolled in Tailscale.'
          exit 0
        fi
        # Incus forwards stdin; the enrollment key never enters guest files or argv.
        incus exec dewford --mode non-interactive -- \
          tailscale up --auth-key=file:/dev/stdin --hostname=dewford --ssh --timeout=60s \
          < ${lib.escapeShellArg authKeyFile}
      '';
    };
  in {
    packages = {
      dewford-enroll = enroll;
      dewford-create = pkgs.writeShellApplication {
        name = "dewford-create";
        runtimeInputs = [pkgs.incus.client pkgs.coreutils];
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
          ${lib.getExe enroll}
          echo 'Bootstrap with: sudo incus exec dewford -- dewford-bootstrap'
        '';
      };
    };
  };
}
