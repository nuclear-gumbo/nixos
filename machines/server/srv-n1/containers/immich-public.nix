{
  home-manager.users."immich-public" = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;

      networks.immich-public = { };

      containers.immich-public-server = {
        image = "ghcr.io/immich-app/immich-server:v3@sha256:79cc1623323d5894922686d8743b4780181428f98eecbfb58ce12c41ef02d1ea";
        autoStart = true;
        network = "immich-public.network";
        ports = [ "127.0.0.1:2284:2283" ];
        volumes = [
          "/var/lib/immich-public/library:/data"
          "/etc/localtime:/etc/localtime:ro"
        ];
        environmentFile = [ "/run/secrets/immich-public.env" ];
        extraConfig = {
          Container = {
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
          Unit = {
            After = [
              "podman-immich-public-redis.service"
              "podman-immich-public-database.service"
            ];
            Wants = [
              "podman-immich-public-redis.service"
              "podman-immich-public-database.service"
            ];
          };
        };
      };

      containers.immich-public-machine-learning = {
        image = "ghcr.io/immich-app/immich-machine-learning:v3@sha256:60dfcf266a9ef3b7376f5678e8c980d4fb61db5fc48c078fe8a326ab1535d60d";
        autoStart = true;
        network = "immich-public.network";
        networkAlias = [ "immich-machine-learning" ];
        volumes = [ "/var/lib/immich-public/model-cache:/cache" ];
        environmentFile = [ "/run/secrets/immich-public.env" ];
        extraConfig = {
          Container = {
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
        };
      };

      containers.immich-public-redis = {
        image = "docker.io/valkey/valkey:8@sha256:640c5e62cea04b6d6f2084232651d0cc70362d31f4f805e7be94dbed6855e8f2";
        autoStart = true;
        network = "immich-public.network";
        networkAlias = [ "redis" ];
        extraConfig = {
          Container = {
            AddCapability = "CHOWN SETGID SETUID";
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
        };
      };

      containers.immich-public-database = {
        image = "ghcr.io/immich-app/postgres:16-vectorchord0.4.3-pgvectors0.2.0@sha256:1a078b237c1d9b420b0ee59147386b4aa60d3a07a8e6a402fc84a57e41b043a4";
        autoStart = true;
        network = "immich-public.network";
        networkAlias = [ "database" ];
        volumes = [ "/var/lib/immich-public/postgres:/var/lib/postgresql/data" ];
        environmentFile = [ "/run/secrets/immich-public.env" ];
        extraPodmanArgs = [ "--shm-size=128mb" ];
        extraConfig = {
          Container = {
            AddCapability = "CHOWN DAC_OVERRIDE FOWNER SETGID SETUID";
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
        };
      };
    };
  };

  sops.secrets."immich-public.env" = {
    sopsFile = ../../../../secrets/srv-n1.immich-public.env;
    format = "binary";
    owner = "immich-public";
    group = "immich-public";
    mode = "0400";
  };
}
