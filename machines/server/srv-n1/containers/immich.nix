{
  home-manager.users.immich = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;

      networks.immich = { };

      containers.immich-server = {
        image = "ghcr.io/immich-app/immich-server:v3@sha256:79cc1623323d5894922686d8743b4780181428f98eecbfb58ce12c41ef02d1ea";
        autoStart = true;
        network = "immich.network";
        ports = [ "127.0.0.1:2283:2283" ];
        volumes = [
          "/var/lib/immich/library:/data"
          "/mnt/photos/Apple-Photos:/external/apple-photos:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
        environmentFile = [ "/run/secrets/immich.env" ];
        extraConfig = {
          Container = {
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
          Unit = {
            After = [
              "podman-immich-redis.service"
              "podman-immich-database.service"
            ];
            Wants = [
              "podman-immich-redis.service"
              "podman-immich-database.service"
            ];
          };
        };
      };

      containers.immich-machine-learning = {
        image = "ghcr.io/immich-app/immich-machine-learning:v3@sha256:60dfcf266a9ef3b7376f5678e8c980d4fb61db5fc48c078fe8a326ab1535d60d";
        autoStart = true;
        network = "immich.network";
        networkAlias = [ "immich-machine-learning" ];
        volumes = [ "/var/lib/immich/model-cache:/cache" ];
        environmentFile = [ "/run/secrets/immich.env" ];
        extraConfig = {
          Container = {
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
        };
      };

      containers.immich-redis = {
        image = "docker.io/valkey/valkey:8@sha256:640c5e62cea04b6d6f2084232651d0cc70362d31f4f805e7be94dbed6855e8f2";
        autoStart = true;
        network = "immich.network";
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

      containers.immich-database = {
        image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
        autoStart = true;
        network = "immich.network";
        networkAlias = [ "database" ];
        volumes = [ "/var/lib/immich/postgres:/var/lib/postgresql/data" ];
        environmentFile = [ "/run/secrets/immich.env" ];
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

  sops.secrets."immich.env" = {
    sopsFile = ../../../../secrets/srv-n1.immich.env;
    format = "binary";
    owner = "immich";
    group = "immich";
    mode = "0400";
  };
}
