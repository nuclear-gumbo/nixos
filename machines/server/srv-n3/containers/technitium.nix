{
  home-manager.users.technitium =
    { pkgs, ... }:
    let
      serve = pkgs.writeText "serve.json" (
        builtins.toJSON {
          TCP."443".HTTPS = true;
          Web."\${TS_CERT_DOMAIN}:443".Handlers."/".Proxy = "http://127.0.0.1:5380";
        }
      );

      netnsOwner = {
        After = [ "podman-technitium-ts.service" ];
        Requires = [ "podman-technitium-ts.service" ];
        PartOf = [ "podman-technitium-ts.service" ];
      };
    in
    {
      home.stateVersion = "25.05";

      services.podman = {
        enable = true;

        containers.technitium-ts = {
          image = "docker.io/tailscale/tailscale:v1.102.5@sha256:c507f3a2a6ab1cabd8d809b98edeb41edbd5c3fb6ad9632ffd098b4c7d0b4065";
          autoStart = true;
          devices = [ "/dev/net/tun" ];
          volumes = [
            "/var/lib/technitium/tailscale:/var/lib/tailscale:Z"
            "${serve}:/config/serve.json:ro"
          ];
          environment = {
            TS_HOSTNAME = "dns";
            TS_STATE_DIR = "/var/lib/tailscale";
            TS_SERVE_CONFIG = "/config/serve.json";
            TS_ACCEPT_DNS = "false";
            TS_USERSPACE = "false";
          };
          environmentFile = [ "/run/secrets/technitium-ts.env" ];
          extraConfig = {
            Container = {
              AddCapability = [
                "NET_ADMIN"
                "NET_BIND_SERVICE"
              ];
              DropCapability = "ALL";
              NoNewPrivileges = true;
            };
            Service.Restart = "always";
            Unit.Upholds = [ "podman-technitium.service" ];
          };
        };

        containers.technitium = {
          image = "docker.io/technitium/dns-server:15.5.0@sha256:2502fd4993d18a8c6665ce6eefb20c76ca21918c5435a015d9485b36e8275b5e";
          autoStart = true;
          network = "container:technitium-ts";
          volumes = [
            "/var/lib/technitium/config:/etc/dns:Z"
            "/var/lib/technitium/logs:/var/log/technitium/dns:Z"
            "/run/secrets/technitium-admin:/run/secrets/admin:ro"
            "/run/secrets/technitium-sso:/run/secrets/sso:ro"
          ];
          environmentFile = [ "/run/secrets/technitium.env" ];
          environment = {
            DNS_SERVER_DOMAIN = "dns";
            DNS_SERVER_ADMIN_PASSWORD_FILE = "/run/secrets/admin";
            DNS_SERVER_FORWARDERS = builtins.concatStringsSep "," [
              "dns.quad9.net (9.9.9.9)"
              "dns.quad9.net (149.112.112.112)"
              "cloudflare-dns.com (1.1.1.1)"
            ];
            DNS_SERVER_FORWARDER_PROTOCOL = "Tls";
            DNS_SERVER_RECURSION = "UseSpecifiedNetworkACL";
            DNS_SERVER_RECURSION_NETWORK_ACL = "100.64.0.0/10,fd7a:115c:a1e0::/48";
            DNS_SERVER_ENABLE_BLOCKING = "true";
            DNS_SERVER_BLOCK_LIST_URLS = builtins.concatStringsSep "," [
              "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/pro.txt"
              "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/fake.txt"
              "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/popupads.txt"
              "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.txt"
            ];
            DNS_SERVER_LOG_FOLDER_PATH = "/var/log/technitium/dns";
            DNS_SERVER_WEB_SERVICE_LOCAL_ADDRESSES = "127.0.0.1";
          };
          extraConfig = {
            Container = {
              AddCapability = "NET_BIND_SERVICE";
              DropCapability = "ALL";
              NoNewPrivileges = true;
            };
            Service.Restart = "always";
            Unit = netnsOwner;
          };
        };
      };
    };

  sops.secrets = {
    "technitium-ts.env" = {
      sopsFile = ../../../../secrets/srv-n3.technitium-ts.env;
      format = "binary";
      owner = "technitium";
      group = "technitium";
      mode = "0400";
    };
    "technitium-admin" = {
      sopsFile = ../../../../secrets/srv-n3.technitium-admin;
      format = "binary";
      owner = "technitium";
      group = "technitium";
      mode = "0400";
    };
    "technitium-sso" = {
      sopsFile = ../../../../secrets/srv-n3.technitium-sso;
      format = "binary";
      owner = "technitium";
      group = "technitium";
      mode = "0400";
    };
    "technitium.env" = {
      sopsFile = ../../../../secrets/srv-n3.technitium.env;
      format = "binary";
      owner = "technitium";
      group = "technitium";
      mode = "0400";
    };
  };
}
