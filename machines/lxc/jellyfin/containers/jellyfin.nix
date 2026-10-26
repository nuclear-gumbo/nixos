{ lib, ... }:
{
  users.groups.render.gid = lib.mkForce 105;
  users.users.jellyfin.extraGroups = [ "render" ];

  home-manager.users.jellyfin = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.jellyfin = {
        image = "docker.io/jellyfin/jellyfin:12.4@sha256:fea863d0cd9ec445985d9c75fc6ed64e38a1d2766cf0c250a33d553f4fc1b771";
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
