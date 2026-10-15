{
  home-manager.users.obsidian = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;

      networks.obsidian = { };

      containers.couchdb = {
        image = "docker.io/library/couchdb:3.5@sha256:3611ce43bd32fe2368997fd41ec6e7270ec8d84aa5fc13c9828e5b15fd6bafe8";
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
        image = "docker.io/cloudflare/cloudflared:2026.10.1@sha256:a15a3b50b8dabd57ac2090e9484c0247dba9dfa1f0df4d298d4317f9d69eb2d5";
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
