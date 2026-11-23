{
  home-manager.users.obsidian = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;

      networks.obsidian = { };

      containers.couchdb = {
        image = "docker.io/library/couchdb:3.5@sha256:907eab5b7e55ab7cfd241d39b90b2a335ea40bef82acee5a37388c08bf201dda";
        autoStart = true;
        network = "obsidian.network";
        networkAlias = [ "couchdb" ];
        ports = [ "127.0.0.1:5984:5984" ];
        volumes = [
          "/var/lib/obsidian/data:/opt/couchdb/data:Z"
          "/var/lib/obsidian/etc:/opt/couchdb/etc/local.d:Z"
        ];
        environmentFile = [ "/run/secrets/obsidian-couchdb.env" ];
        userNS = "keep-id:uid=5984,gid=5984";
        extraConfig = {
          Container = {
            AddCapability = "CHOWN SETGID SETUID";
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
        };
      };

      containers.cloudflared = {
        image = "docker.io/cloudflare/cloudflared:2026.11.2@sha256:55c7e3e8d89d5e8d20b75a82f3602cbf98e06db406e73e282073cfdc5a9a3af6";
        autoStart = true;
        network = "obsidian.network";
        exec = "tunnel --no-autoupdate run";
        environmentFile = [ "/run/secrets/obsidian-cloudflared.env" ];
        extraConfig = {
          Container = {
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
          Unit = {
            After = [ "podman-couchdb.service" ];
            Wants = [ "podman-couchdb.service" ];
          };
        };
      };
    };
  };

  sops.secrets."obsidian-couchdb.env" = {
    sopsFile = ../../../../secrets/srv-n1.obsidian-couchdb.env;
    format = "binary";
    owner = "obsidian";
    group = "obsidian";
    mode = "0400";
  };

  sops.secrets."obsidian-cloudflared.env" = {
    sopsFile = ../../../../secrets/srv-n1.obsidian-cloudflared.env;
    format = "binary";
    owner = "obsidian";
    group = "obsidian";
    mode = "0400";
  };
}
