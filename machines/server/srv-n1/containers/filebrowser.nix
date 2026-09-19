{
  home-manager.users.filebrowser =
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
      home.stateVersion = "25.05";

      services.podman = {
        enable = true;
        containers.filebrowser = {
          image = "ghcr.io/gtsteffaniak/filebrowser:1.5.6-stable@sha256:7c5d7ac8ffda31294d278063cf9d2e04303b39e6dce1f4c691342240ca7703b8";
          autoStart = true;
          ports = [ "127.0.0.1:8090:8080" ];
          userNS = "keep-id:uid=1000,gid=1000";
          volumes = [
            "/var/lib/filebrowser/data:/home/filebrowser/data"
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
    sopsFile = ../../../../secrets/srv-n1.filebrowser.env;
    format = "binary";
    owner = "filebrowser";
    group = "filebrowser";
    mode = "0400";
  };
}
