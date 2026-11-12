{
  home-manager.users."uptime-kuma" = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.uptime-kuma = {
        image = "docker.io/louislam/uptime-kuma:2.5.10@sha256:3256c6ae95a1d9707da05fe21c4a7f82cbc20e1f7dec8abdb301cae12cb1246f";
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
