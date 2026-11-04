{
  home-manager.users.gumbo = { ... }: {
    services.podman = {
      enable = true;
      containers.newt = {
        image = "docker.io/fosrl/newt:1.20@sha256:2170e673c4c72d905764fa22e83d0ae0aa3239fb1ab3b9fcaefb2b00fffb2d6e";
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
