{ lib, ... }:
{
  users.groups.render.gid = lib.mkForce 105;
  users.users.jellyfin.extraGroups = [ "render" ];

  home-manager.users.jellyfin = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.jellyfin = {
        image = "docker.io/jellyfin/jellyfin:12.2@sha256:357724bf0ae27a672c7cbaa899db2d9abeb13dbd8657ccce750258a4c059d037";
        autoStart = true;
        ports = [ "8096:8096" ];
        volumes = [
          "/var/lib/jellyfin/config:/config:Z"
          "/var/lib/jellyfin/cache:/cache:Z"
          "/srv/media:/media:ro"
        ];
        devices = [ "/dev/dri/renderD128" ];
        extraPodmanArgs = [ "--group-add=keep-groups" ];
        extraConfig.Container.NoNewPrivileges = true;
        extraConfig.Service = {
          Restart = "on-failure";
          TimeoutStartSec = 900;
        };
      };
    };
  };
}
