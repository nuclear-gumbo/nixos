{
  home-manager.users.lubelogger = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.lubelogger = {
        image = "ghcr.io/hargata/lubelogger:v1.7.4@sha256:483a9d7582c4e6258615fd822b3de4193b4fcc4230d0a92432c6d407faf75af2";
        autoStart = true;
        ports = [ "127.0.0.1:8081:8080" ];
        volumes = [
          "/var/lib/lubelogger/data:/App/data:Z"
          "/var/lib/lubelogger/keys:/root/.aspnet/DataProtection-Keys:Z"
        ];
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
