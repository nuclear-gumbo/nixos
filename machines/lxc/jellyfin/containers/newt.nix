{
  home-manager.users.newt = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.newt = {
        image = "docker.io/fosrl/newt:1.20@sha256:03561e3f3d10b94ee7839318ae46e5acf8b4431550ea1d0e15666ab60caa2e43";
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
