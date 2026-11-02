{
  home-manager.users.ntfy = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.ntfy = {
        image = "docker.io/binwiederhier/ntfy:v2.37.0@sha256:3176f6f3f0a111c7915a102b94976be92d590b6ff9da198c3d48fa9e50f1b2ef";
        autoStart = true;
        exec = "serve";
        ports = [ "127.0.0.1:8084:8080" ];
        environmentFile = [ "/run/secrets/ntfy.env" ];
        volumes = [
          "/var/lib/ntfy/cache:/var/cache/ntfy"
          "/var/lib/ntfy/etc:/etc/ntfy"
          "/var/lib/ntfy/data:/var/lib/ntfy"
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

  sops.secrets."ntfy.env" = {
    sopsFile = ../../../../../secrets/srv-n1.ntfy.env;
    format = "binary";
    owner = "ntfy";
    group = "ntfy";
    mode = "0400";
  };
}
