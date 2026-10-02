{
  home-manager.users.gumbo = { ... }: {
    services.podman = {
      enable = true;
      containers.newt = {
        image = "docker.io/fosrl/newt:1.18@sha256:7fed6605e0a104a337e1cb903bbb1225f80c7f6e5e56ff1eb1d70c57740d8e0f";
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
