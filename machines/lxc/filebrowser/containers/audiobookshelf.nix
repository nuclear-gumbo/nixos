{ lib, ... }:
{
  systemd.tmpfiles.rules = [ "d /var/lib/audiobookshelf/{config,metadata} 0700 gumbo gumbo -" ];

  home-manager.users.gumbo = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.audiobookshelf = {
        image = "ghcr.io/advplyr/audiobookshelf:2.37.2@sha256:b897c33f05972fb1bf484f7487bc878fa91ec8691335c1db6e2929c3a7658efa";
        autoStart = true;
        ports = [ "127.0.0.1:13378:13378" ];
        environment = {
          PORT = 13378;
        };
        volumes = [
          "/srv/media/audiobooks:/audiobooks:Z"
          "/srv/media/books:/books:Z"
          "/srv/media/podcasts:/podcasts:Z"
          "/var/lib/audiobookshelf/config:/config:Z"
          "/var/lib/audiobookshelf/metadata:/metadata:Z"
        ];
        extraConfig = {
          Container = {
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service = {
            Restart = "on-failure";
            TimeoutStartSec = 900;
          };
        };
      };
    };
  };
}
