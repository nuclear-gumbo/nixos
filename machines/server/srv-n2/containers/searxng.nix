{
  home-manager.users.searxng = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;

      networks.searxng = { };

      containers.searxng = {
        image = "docker.io/searxng/searxng:latest@sha256:98a7ef5023169bb67a0782a4d36a8347d461d140426712bff92b016c90afea2d";
        autoStart = true;
        network = "searxng.network";
        ports = [ "127.0.0.1:8082:8080" ];
        volumes = [
          "/var/lib/searxng/config:/etc/searxng:rw"
          "/var/lib/searxng/cache:/var/cache/searxng:rw"
        ];
        environment = {
          SEARXNG_BASE_URL = "https://libresearch.space/";
          SEARXNG_LIMITER = "true";
          SEARXNG_PUBLIC_INSTANCE = "true";
          SEARXNG_VALKEY_URL = "valkey://redis:6379/0";
          # a solved anubis challenge only replays a GET
          SEARXNG_METHOD = "GET";
        };
        environmentFile = [ "/run/secrets/searxng.env" ];
        extraConfig = {
          Container = {
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
          Unit = {
            After = [ "podman-searxng-redis.service" ];
            Wants = [ "podman-searxng-redis.service" ];
          };
        };
      };

      containers.searxng-redis = {
        image = "docker.io/valkey/valkey:8-alpine@sha256:081c2f5cb575efc901aa80ff9cdbd1ec6a301682fd35e1ebb4b0990a4a4a8507";
        autoStart = true;
        network = "searxng.network";
        networkAlias = [ "redis" ];
        volumes = [ "/var/lib/searxng/redis-data:/data" ];
        exec = "valkey-server --save 30 1 --loglevel warning --maxmemory 256mb --maxmemory-policy allkeys-lru";
        extraConfig = {
          Container = {
            DropCapability = "ALL";
            AddCapability = [
              "CHOWN"
              "DAC_OVERRIDE"
              "FOWNER"
              "SETGID"
              "SETUID"
            ];
            NoNewPrivileges = false;
          };
          Service.Restart = "always";
        };
      };
    };
  };

  sops.secrets."searxng.env" = {
    sopsFile = ../../../../secrets/srv-n2.searxng.env;
    format = "binary";
    owner = "searxng";
    group = "searxng";
    mode = "0400";
  };
}
