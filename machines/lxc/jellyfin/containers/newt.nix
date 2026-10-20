{
  home-manager.users.newt = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.newt = {
        image = "docker.io/fosrl/newt:1.19@sha256:0189c8287058b800cca825590e4c39946b3815344ca48678dd0b96616d639319";
        autoStart = true;
        environmentFile = [ "/run/secrets/newt.env" ];
        devices = [ "/dev/net/tun" ];
        extraPodmanArgs = [
          "--cap-add=NET_ADMIN"
          "--network=pasta:--map-host-loopback,169.254.1.2"
        ];
        extraConfig.Service.RestartSec = 2;
      };
    };
  };

  sops.secrets."newt.env" = {
    sopsFile = ../../../../secrets/jellyfin.newt.env;
    format = "binary";
    owner = "newt";
    group = "newt";
    mode = "0400";
  };
}
