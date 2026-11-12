{
  home-manager.users."immich-public" = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;

      networks.immich-public = { };

      containers.immich-public-server = {
        image = "ghcr.io/immich-app/immich-server:v3.4.1@sha256:7c489add298fc2f92cda4c777de6462aa206877e04087b815f62c7664af0b53b";
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
        image = "ghcr.io/immich-app/immich-machine-learning:v3.4.1@sha256:8adebf414256f6e4f837bfbb66fa94f14f4da7260e3a1d65cbba49e4e35d8764";
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
        image = "docker.io/valkey/valkey:8@sha256:8f836008e0986c36adf50da714c7060cf689dbb335f61fe077939d90fa650809";
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
        image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
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
