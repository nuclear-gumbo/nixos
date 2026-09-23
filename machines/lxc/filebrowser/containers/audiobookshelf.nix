{ lib, ... }:
{
  systemd.tmpfiles.rules = [ "d /var/lib/audiobookshelf/{config,metadata} 0700 gumbo gumbo -" ];

  home-manager.users.gumbo = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.audiobookshelf = {
        image = "ghcr.io/advplyr/audiobookshelf:2.36.1@sha256:3528a93b6442ffe54bd46771bbbab7c97084e1101071586d9dc2254f30bb4358";
        autoStart = true;
        ports = [ "127.0.0.1:13378:80" ];
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
          }
          Servive = {
            Restart = "on-failure";
            TimeoutStartSec = 900;
          }
        }
      };
    };
  };
}
