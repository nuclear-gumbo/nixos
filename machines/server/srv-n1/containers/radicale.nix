{
  home-manager.users.radicale =
    { pkgs, ... }:
    let
      radicaleConfig = pkgs.writeText "config" ''
        [server]
        hosts = 0.0.0.0:5232

        [auth]
        type = htpasswd
        htpasswd_filename = /run/secrets/users
        htpasswd_encryption = bcrypt
        htpasswd_cache = True

        [rights]
        type = owner_only

        [storage]
        filesystem_folder = /var/lib/radicale/collections
      '';
    in
    {
      home.stateVersion = "25.05";

      services.podman = {
        enable = true;
        containers.radicale = {
          image = "ghcr.io/nuclear-gumbo/radicale:3.8.1@sha256:1f585971665e4ad5315b99239f142404fb2186498c9153625bea574e03dc5b8f";
          autoStart = true;
          ports = [ "127.0.0.1:5232:5232" ];
          volumes = [
            "/var/lib/radicale/collections:/var/lib/radicale/collections:Z"
            "${radicaleConfig}:/etc/radicale/config:ro"
            "/run/secrets/radicale.users:/run/secrets/users:ro"
          ];
          environment = {
            # s6 keeps its live state in /run when the rootfs is read-only
            S6_READ_ONLY_ROOT = 1;
          };
          extraConfig = {
            Container = {
              DropCapability = "ALL";
              NoNewPrivileges = true;
              ReadOnly = true;
              Tmpfs = [
                "/run"
                "/tmp"
              ];
            };
            Service.Restart = "always";
          };
        };
      };
    };

  sops.secrets."radicale.users" = {
    sopsFile = ../../../../secrets/srv-n1.radicale.users;
    format = "binary";
    path = "/run/secrets/radicale.users";
    owner = "radicale";
    group = "radicale";
    mode = "0400";
  };
}
