{
  home-manager.users.karakeep = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;

      networks.karakeep = { };

      containers.karakeep = {
        image = "ghcr.io/karakeep-app/karakeep:release@sha256:6f7d32ef296ddf1fc7c67ff56b8a201b7006a6a47b92b202afee1338841b353d";
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
            AddCapability = "CHOWN SETGID SETUID";
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
        image = "ghcr.io/karakeep-app/karakeep-chrome:latest@sha256:00fb4fa9c37aa74c58e74d0bdd16c4e3b81dddb5f264917c879f9579c3b3ad95";
        autoStart = true;
        network = "karakeep.network";
        networkAlias = [ "chrome" ];
        exec = "--no-sandbox --disable-gpu --disable-dev-shm-usage --hide-scrollbars --disable-blink-features=AutomationControlled --window-size=1440,900";
        extraConfig = {
          Container = {
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
        };
      };

      containers.karakeep-meilisearch = {
        image = "docker.io/getmeili/meilisearch:v1.56.2@sha256:9600db22be3fcbf3d506176d3a73dd70a65c5719d9aa1d2837355b75afb8f4fb";
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
