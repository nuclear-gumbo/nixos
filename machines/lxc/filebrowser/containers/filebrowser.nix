{
  users.manageLingering = true;

  # pinned, the host-side idmap passes 1000:1000 straight through to the nas
  users.users.gumbo = {
    uid = 1000;
    group = "gumbo";
    linger = true;
  };
  users.groups.gumbo.gid = 1000;

  systemd.tmpfiles.rules = [ "d /var/lib/filebrowser/data 0700 gumbo gumbo -" ];

  home-manager.users.gumbo =
    { pkgs, ... }:
    let
      # kept out of the data dir, filebrowser pulls every *-config.yaml beside it
      settings = pkgs.writeText "config.yaml" ''
        server:
          cacheDir: /home/filebrowser/data/tmp
          port: 8080
          baseURL: "/"
          sources:
            - path: /home/filebrowser/data/files
              name: "home"
              config:
                defaultEnabled: true
            - path: /srv/media
              name: "media"
              config:
                defaultEnabled: true
            - path: /srv/p2p
              name: "p2p"
              config:
                defaultEnabled: true
            - path: /srv/scratch
              name: "scratch"
              config:
                defaultEnabled: true
            - path: /srv/scratch_2
              name: "scratch_2"
              config:
                defaultEnabled: true
        userDefaults:
          account:
            permissions:
              modify: true
              create: true
              delete: true
              share: true
        auth:
          methods:
            password:
              enabled: false
            oidc:
              enabled: true
              issuerUrl: "https://id.senseii.dev"
              userIdentifier: "preferred_username"
      '';
    in
    {
      services.podman = {
        enable = true;
        containers.filebrowser = {
          image = "ghcr.io/gtsteffaniak/filebrowser:1.5.6-stable@sha256:7c5d7ac8ffda31294d278063cf9d2e04303b39e6dce1f4c691342240ca7703b8";
          autoStart = true;
          ports = [ "127.0.0.1:8080:8080" ];
          userNS = "keep-id:uid=1000,gid=1000";
          volumes = [
            "/var/lib/filebrowser/data:/home/filebrowser/data"
            "/srv/media:/srv/media"
            "/srv/p2p:/srv/p2p"
            "/srv/scratch:/srv/scratch"
            "/srv/scratch_2:/srv/scratch_2"
            "${settings}:/etc/filebrowser/config.yaml:ro"
          ];
          environment.FILEBROWSER_CONFIG = "/etc/filebrowser/config.yaml";
          # holds FILEBROWSER_OIDC_CLIENT_ID and FILEBROWSER_OIDC_CLIENT_SECRET
          environmentFile = [ "/run/secrets/filebrowser.env" ];
          extraConfig = {
            Container = {
              DropCapability = "ALL";
              NoNewPrivileges = true;
            };
            Service.Restart = "always";
          };
        };
      };
    };

  sops.secrets."filebrowser.env" = {
    sopsFile = ../../../../secrets/filebrowser.env;
    format = "binary";
    owner = "gumbo";
    group = "gumbo";
    mode = "0400";
  };
}
