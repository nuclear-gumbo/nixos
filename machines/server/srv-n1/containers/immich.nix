{
  home-manager.users.immich = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;

      networks.immich = { };

      containers.immich-server = {
        image = "ghcr.io/immich-app/immich-server:v3.3.5@sha256:485d546a2e31d6a8b4db8423fcba5c109de8c218d93410af115fd1ccfc4352a6";
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
        image = "ghcr.io/immich-app/immich-machine-learning:v3.3.5@sha256:5b28c9352c8374b8a1ed96fbdd8d6755fea6e43510ec43fdf6538aa02ea40f56";
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
        image = "docker.io/valkey/valkey:8@sha256:8f836008e0986c36adf50da714c7060cf689dbb335f61fe077939d90fa650809";
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
        image = "ghcr.io/immich-app/postgres:16-vectorchord0.4.3-pgvectors0.2.0@sha256:1a078b237c1d9b420b0ee59147386b4aa60d3a07a8e6a402fc84a57e41b043a4";
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
