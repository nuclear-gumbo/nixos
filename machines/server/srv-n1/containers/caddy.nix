{
  home-manager.users.caddy =
    { pkgs, ... }:
    let
      caddyfile = pkgs.writeText "Caddyfile" ''
        {
          http_port 8080
          https_port 8443
        }

        {env.DOMAIN} {
          reverse_proxy 169.254.1.2:4533
          tls {
            dns cloudflare {env.CF_API_TOKEN}
          }
        }
      '';
    in
    {
      home.stateVersion = "25.05";

      services.podman = {
        enable = true;
        containers.caddy = {
          image = "ghcr.io/caddybuilds/caddy-cloudflare:2.11@sha256:ce9c63ce737fa18130b45d7ffc5b729ed857cc3f18e29472993be2b8224cce2c";
          autoStart = true;
          ports = [ "100.69.69.210:8443:8443" ];
          extraPodmanArgs = [ "--network=pasta:--map-host-loopback,169.254.1.2" ];
          volumes = [
            "/var/lib/caddy/data:/data:Z"
            "/var/lib/caddy/config:/config:Z"
            "${caddyfile}:/etc/caddy/Caddyfile:ro"
          ];
          environmentFile = [ "/run/secrets/caddy.env" ];
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

  sops.secrets."caddy.env" = {
    sopsFile = ../../../../secrets/srv-n1.caddy.env;
    format = "binary";
    owner = "caddy";
    group = "caddy";
    mode = "0400";
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 8443 ];

  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -d 100.69.69.210 -p tcp --dport 443 -j REDIRECT --to-port 8443
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t nat -D PREROUTING -d 100.69.69.210 -p tcp --dport 443 -j REDIRECT --to-port 8443 || true
  '';
}
