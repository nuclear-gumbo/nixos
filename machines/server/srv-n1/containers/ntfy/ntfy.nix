{
  home-manager.users.ntfy = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.ntfy = {
        image = "docker.io/binwiederhier/ntfy:v2.36.0@sha256:fb48c413eb11d50339962b5d62cddce0f800e7f77c626d638a7c20cb7e9c4465";
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
