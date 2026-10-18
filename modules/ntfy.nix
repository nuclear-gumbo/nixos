{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ntfy;
  host = config.networking.hostName;

  alert = topic: script: {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.curl ];
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = config.sops.secrets."ntfy-alerts.env".path;
    };
    script = ''
      send() {
        curl -fsS --retry 3 -u "$NTFY_USER" -H "Priority: default" -d "$1" https://ntfy.goc.dev/${topic}
      }
      ${script}
    '';
  };

  daily = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 09:00:00";
      Persistent = true;
    };
  };
in
{
  options.ntfy = {
    enable = lib.mkEnableOption "ntfy storage and uptime alerts";
    backups.enable = lib.mkEnableOption "ntfy alerts for pbs-backup";
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable || cfg.backups.enable) {
      sops.secrets."ntfy-alerts.env" = {
        sopsFile = ../secrets/ntfy.env;
        format = "binary";
        owner = "root";
        group = "root";
        mode = "0400";
      };
    })

    (lib.mkIf cfg.enable {
      systemd.services.ntfy-storage = alert "storage" ''
        used="$(df -l -x tmpfs -x devtmpfs -x efivarfs -x overlay -x squashfs --output=pcent | tail -n +2 | tr -d ' %' | sort -n | tail -1)"
        if [ "$used" -ge 90 ]; then
          send "Hey! ${host}'s storage only has 10% free. You should take a look at that when you have the chance"
        fi
      '';
      systemd.timers.ntfy-storage = daily;

      systemd.services.ntfy-uptime = alert "uptime" ''
        read -r up _ < /proc/uptime
        days=$((''${up%.*} / 86400))
        if [ "$days" -ge 7 ]; then
          send "Hey! ${host} hasn't rebooted in $days days. You should check on that server."
        fi
      '';
      systemd.timers.ntfy-uptime = daily;
    })

    (lib.mkIf cfg.backups.enable {
      systemd.services.ntfy-backup-ok = alert "backups" ''
        send "Hey! ${host} backed up with no issues."
      '';
      systemd.services.ntfy-backup-failed = alert "backups" ''
        send "Hey! Something went wrong with ${host}'s backup. Check it out when you're free."
      '';
      systemd.services.pbs-backup = {
        onSuccess = [ "ntfy-backup-ok.service" ];
        onFailure = [ "ntfy-backup-failed.service" ];
      };
    })
  ];
}
