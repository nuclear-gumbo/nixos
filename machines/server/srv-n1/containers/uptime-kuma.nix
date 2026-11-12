{
  home-manager.users."uptime-kuma" = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.uptime-kuma = {
        image = "docker.io/louislam/uptime-kuma:2.5.11@sha256:7554dba313c84e44fee921ef3b5626ba1c711e412e82815e8c957517026112a9";
        autoStart = true;
        ports = [
          "127.0.0.1:3001:3001" # private
          "127.0.0.1:3002:3001" # senseii
          "127.0.0.1:3003:3001" # libresearch
          "127.0.0.1:3004:3001" # pasted
        ];
        volumes = [ "/var/lib/uptime-kuma/data:/app/data:Z" ];
        extraConfig = {
          Container = {
            AddCapability = "SETGID SETUID";
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
        };
      };
    };
  };
}
