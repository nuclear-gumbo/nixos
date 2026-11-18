{ lib, ... }:
{
  systemd.tmpfiles.rules = [ "d /var/lib/audiobookshelf/{config,metadata} 0700 gumbo gumbo -" ];

  home-manager.users.gumbo = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.audiobookshelf = {
        image = "ghcr.io/advplyr/audiobookshelf:2.38.0@sha256:60064c23f32fd9099fd39e82c5132c51701d1221135bbca04cd099b589e1edc3";
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
