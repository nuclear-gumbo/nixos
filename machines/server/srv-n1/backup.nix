{ config, pkgs, ... }:
{
  sops.secrets."srv-n1.token" = {
    sopsFile = ../../../secrets/srv-n1.pbs;
    format = "binary";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets."srv-n1.key" = {
    sopsFile = ../../../secrets/srv-n1.pbs.key;
    format = "binary";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  environment.systemPackages = [ pkgs.proxmox-backup-client ];

  systemd.services.pbs-backup = {
    description = "Proxmox Backup Server backup";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    environment = {
      PBS_REPOSITORY = "servers@pbs!srv-n1@10.10.1.99:backup";
      PBS_FINGERPRINT = "8c:93:31:12:89:30:25:95:d5:93:c5:e5:da:f1:c2:88:55:bc:e1:83:4f:ca:b1:26:5c:dd:52:9f:b6:a1:b4:18";
    };

    serviceConfig = {
      Type = "oneshot";
      LimitNOFILE = 65536;
      LoadCredential = [ "token:${config.sops.secrets."srv-n1.token".path}" ];
    };

    script = ''
      export PBS_PASSWORD="$(cat "$CREDENTIALS_DIRECTORY/token")"
      exec ${pkgs.proxmox-backup-client}/bin/proxmox-backup-client backup \
        root.pxar:/ \
        --keyfile /run/secrets/srv-n1.key \
        --exclude /mnt \
        --exclude /var/cache \
        --exclude /var/tmp \
        --exclude /var/lib/systemd/coredump \
        --exclude '/home/*/.cache' \
        --ns servers/srv-n1 --backup-id srv-n1 \
        --change-detection-mode=metadata
    '';
  };

  systemd.timers.pbs-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
