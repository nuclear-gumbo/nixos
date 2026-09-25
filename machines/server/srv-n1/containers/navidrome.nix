{
  home-manager.users.navidrome = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.navidrome = {
        image = "docker.io/deluan/navidrome:0.64.2@sha256:38dc2727bfcfd5ede290f8ada114fc90368146f265ae4701ddddbcbe2a44ee52";
        autoStart = true;
        ports = [ "127.0.0.1:4533:4533" ];
        volumes = [
          "/var/lib/navidrome/data:/data:Z"
          "/mnt/music:/music:ro"
        ];
        environment = {
          ND_AcceptExtensions = ".mp4,.flac,.m4a";
        };
        extraConfig = {
          Container = {
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
        };
      };
    };
  };
}
