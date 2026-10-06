{
  home-manager.users.vaultwarden = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.vaultwarden = {
        image = "docker.io/vaultwarden/server:1.37.4@sha256:efb3cde962015fcc036b2ea625242248611943b27212ebf4392841fb30fad055";
        autoStart = true;
        ports = [ "127.0.0.1:8000:8000" ];
        volumes = [ "/var/lib/vaultwarden/data:/data:Z" ];
        environmentFile = [ "/run/secrets/vaultwarden.env" ];
        environment = {
          SIGNUPS_ALLOWED = "false";
          ROCKET_PORT = "8000";
          WEBSOCKET_ENABLED = "true";
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

  sops.secrets."vaultwarden.env" = {
    sopsFile = ../../../../secrets/srv-n1.vaultwarden.env;
    format = "binary";
    owner = "vaultwarden";
    group = "vaultwarden";
    mode = "0400";
  };
}
