{ lib, ... }:
{
  users.groups.render.gid = lib.mkForce 105;
  users.users.jellyfin.extraGroups = [ "render" ];

  home-manager.users.jellyfin = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.jellyfin = {
        image = "docker.io/jellyfin/jellyfin:12.1@sha256:78d3ea1207d1322471fcac39a614f004f2ccf7e878f95ab2977d752f07e4dd7e";
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
