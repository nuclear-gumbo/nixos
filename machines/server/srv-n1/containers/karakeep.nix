{
  home-manager.users.karakeep = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;

      networks.karakeep = { };

      containers.karakeep = {
        image = "ghcr.io/karakeep-app/karakeep:release@sha256:b069e4307dec06ea06d16989c6861c30a1ff208568be44ed5fb5d422cd3e950c";
        autoStart = true;
        ports = [ "127.0.0.1:3000:3000" ];
        volumes = [ "/var/lib/karakeep/data:/data:Z" ];
        network = "karakeep.network";
        environmentFile = [ "/run/secrets/karakeep.env" ];
        environment = {
          MEILI_ADDR = "http://meilisearch:7700";
          BROWSER_WEB_URL = "http://chrome:9222";
          DATA_DIR = "/data";
        };
        extraPodmanArgs = [ "--memory=3g" ];
        extraConfig = {
          Container = {
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
          Unit = {
            After = [
              "podman-karakeep-chrome.service"
              "podman-karakeep-meilisearch.service"
            ];
            Wants = [
              "podman-karakeep-chrome.service"
              "podman-karakeep-meilisearch.service"
            ];
          };
        };
      };

      containers.karakeep-chrome = {
        image = "gcr.io/zenika-hub/alpine-chrome:124@sha256:1a0046448e0bb6c275c88f86e01faf0de62b02ec8572901256ada0a8c08be23f";
        autoStart = true;
        network = "karakeep.network";
        networkAlias = [ "chrome" ];
        exec = "--no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-address=0.0.0.0 --remote-debugging-port=9222 --hide-scrollbars";
        extraConfig = {
          Container = {
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
        };
      };

      containers.karakeep-meilisearch = {
        image = "docker.io/getmeili/meilisearch:v1.54.0@sha256:0bf32debcbfa8ba4e418679025f4935884972171513c92f0584689ff994a61df";
        autoStart = true;
        network = "karakeep.network";
        networkAlias = [ "meilisearch" ];
        volumes = [ "/srv/karakeep/meili_data:/meili_data:Z" ];
        environmentFile = [ "/run/secrets/karakeep.env" ];
        environment = {
          MEILI_NO_ANALYTICS = "true";
          MEILI_UPGRADE_DB = "true";
        };
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

  sops.secrets."karakeep.env" = {
    sopsFile = ../../../../secrets/srv-n1.karakeep.env;
    format = "binary";
    owner = "karakeep";
    group = "karakeep";
    mode = "0400";
  };
}
