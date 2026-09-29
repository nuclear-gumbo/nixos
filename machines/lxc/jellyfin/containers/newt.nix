{
  home-manager.users.newt = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.newt = {
        image = "docker.io/fosrl/newt:1.18@sha256:07507a530f3f239bee4dc208aabdd25095df650f132e926245659e1a67aa5de9";
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
