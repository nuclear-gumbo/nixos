{
  home-manager.users.gumbo = { ... }: {
    services.podman = {
      enable = true;
      containers.newt = {
        image = "docker.io/fosrl/newt:1.19@sha256:c89f01cb387bf6c598959036cbf56306b068a43e8784345bee7398b7af8ee2e1";
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
