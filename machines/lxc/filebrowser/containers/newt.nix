{
  home-manager.users.gumbo = { ... }: {
    services.podman = {
      enable = true;
      containers.newt = {
        image = "docker.io/fosrl/newt:1.19@sha256:0189c8287058b800cca825590e4c39946b3815344ca48678dd0b96616d639319";
        autoStart = true;
        environmentFile = [ "/run/secrets/newt.env" ];
        devices = [ "/dev/net/tun" ];
        extraPodmanArgs = [ "--network=pasta:--map-host-loopback,169.254.1.2" ];
        extraConfig = {
          Container = {
            AddCapability = "NET_ADMIN";
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.RestartSec = 2;
        };
      };
    };
  };

  sops.secrets."newt.env" = {
    sopsFile = ../../../../secrets/filebrowser.newt.env;
    format = "binary";
    owner = "gumbo";
    group = "gumbo";
    mode = "0400";
  };
}
