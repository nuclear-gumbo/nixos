{
  home-manager.users.mealie = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.mealie = {
        image = "ghcr.io/mealie-recipes/mealie:v3.30.0@sha256:90f83da6f3ab0a421efc827118a556168573930105f13fa3321768f42163d784";
        autoStart = true;
        ports = [ "127.0.0.1:9000:9000" ];
        volumes = [ "/var/lib/mealie/data:/app/data:Z" ];
        environmentFile = [ "/run/secrets/mealie.env" ];
        environment = {
          ALLOW_SIGNUP = "false";
          PUID = 1000;
          PGID = 1000;
          TZ = "America/New_York";
          TOKEN_TIME = 720;
        };
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

  sops.secrets."mealie.env" = {
    sopsFile = ../../../../secrets/srv-n1.mealie.env;
    format = "binary";
    owner = "mealie";
    group = "mealie";
    mode = "0400";
  };
}
