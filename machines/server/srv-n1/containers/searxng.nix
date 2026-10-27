{
  home-manager.users.searxng = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;

      networks.searxng = { };

      containers.searxng = {
        image = "docker.io/searxng/searxng:latest@sha256:0f48ffe2152f388f5eaede27f96b610449cebfc890d0ad457304475a54ad7b6e";
        autoStart = true;
        network = "searxng.network";
        ports = [ "127.0.0.1:8082:8080" ];
        volumes = [
          "/var/lib/searxng/config:/etc/searxng:rw"
          "/var/lib/searxng/cache:/var/cache/searxng:rw"
        ];
        environmentFile = [ "/run/secrets/searxng.env" ];
        extraConfig = {
          Container = {
            AddCapability = "CHOWN DAC_OVERRIDE";
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
        image = "docker.io/valkey/valkey:8-alpine@sha256:2602ace2be6569bc2bbb06f873776516ab9089821525be34f4305c67eb9db02a";
        autoStart = true;
        network = "searxng.network";
        networkAlias = [ "redis" ];
        volumes = [ "/var/lib/searxng/redis-data:/data" ];
        exec = "valkey-server --save 30 1 --loglevel warning --maxmemory 256mb --maxmemory-policy allkeys-lru";
        extraConfig = {
          Container = {
            AddCapability = "CHOWN SETGID SETUID";
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
        };
      };
    };
  };

  sops.secrets."searxng.env" = {
    sopsFile = ../../../../secrets/srv-n1.searxng.env;
    format = "binary";
    owner = "searxng";
    group = "searxng";
    mode = "0400";
  };
}
