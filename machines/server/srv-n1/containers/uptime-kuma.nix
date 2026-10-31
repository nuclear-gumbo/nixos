{
  home-manager.users."uptime-kuma" = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.uptime-kuma = {
        image = "docker.io/louislam/uptime-kuma:2.5.9@sha256:e88415a90dd2f7efecdbc18de0490aff292764a3ac471531bf1d0481725591bd";
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
