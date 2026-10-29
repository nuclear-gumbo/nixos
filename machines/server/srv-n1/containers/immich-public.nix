{
  home-manager.users."immich-public" = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;

      networks.immich-public = { };

      containers.immich-public-server = {
        image = "ghcr.io/immich-app/immich-server:v3.3.5@sha256:485d546a2e31d6a8b4db8423fcba5c109de8c218d93410af115fd1ccfc4352a6";
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
        image = "ghcr.io/immich-app/immich-machine-learning:v3.3.5@sha256:5b28c9352c8374b8a1ed96fbdd8d6755fea6e43510ec43fdf6538aa02ea40f56";
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
