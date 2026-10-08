{
  home-manager.users.anubis =
    { pkgs, ... }:
    let
      image = "ghcr.io/techarohq/anubis:v1.28.0@sha256:48deacf791149e27c2cf6f5d8b4243e1a3db7a5816a168de0af6e58d9a519e2e";

      # the searx.space checker runs a plain firefox UA, so it only passes by address
      libresearchPolicy = pkgs.writeTextDir "botPolicies.yaml" ''
        bots:
          - import: (data)/meta/default-config.yaml

          - name: searx-space-checker
            action: ALLOW
            remote_addresses:
              - 167.235.158.251/32
              - 2a01:4f8:1c1c:8fc2::/64

          - name: outside-search
            action: ALLOW
            expression: '!path.startsWith("/search")'

          - name: search
            action: CHALLENGE
            path_regex: ^/search
      '';

      wikiPolicy = pkgs.writeTextDir "botPolicies.yaml" ''
        bots:
          - import: (data)/meta/default-config.yaml

          # makes sure link-previews arent blocked
          - name: link-previews
            action: ALLOW
            user_agent_regex: (LinkedInBot|Twitterbot|Slackbot|Discordbot|facebookexternalhit|Mastodon)

          - name: feeds-and-meta
            action: ALLOW
            path_regex: ^/(index\.xml|sitemap\.xml|robots\.txt)$
      '';

      hardening = {
        Container = {
          DropCapability = "ALL";
          NoNewPrivileges = true;
          ReadOnly = true;
        };
        Service.Restart = "always";
      };
    in
    {
      home.stateVersion = "25.05";

      services.podman = {
        enable = true;

        containers.anubis-libresearch = {
          inherit image;
          autoStart = true;
          ports = [
            "127.0.0.1:8084:8080"
            "9084:9090"
          ];
          extraPodmanArgs = [ "--network=pasta:--map-host-loopback,169.254.1.2" ];
          volumes = [ "${libresearchPolicy}:/data/cfg:ro" ];
          environment = {
            BIND = ":8080";
            TARGET = "http://169.254.1.2:8082";
            POLICY_FNAME = "/data/cfg/botPolicies.yaml";
            COOKIE_DOMAIN = "libresearch.space";
            DIFFICULTY = 4;
            METRICS_BIND = ":9090";
          };
          extraConfig = hardening;
        };

        containers.anubis-pasted = {
          inherit image;
          autoStart = true;
          ports = [
            "127.0.0.1:8085:8080"
            "9085:9090"
          ];
          extraPodmanArgs = [ "--network=pasta:--map-host-loopback,169.254.1.2" ];
          environment = {
            BIND = ":8080";
            TARGET = "http://169.254.1.2:8083";
            COOKIE_DOMAIN = "pasted.space";
            DIFFICULTY = 4;
            METRICS_BIND = ":9090";
          };
          extraConfig = hardening;
        };

        containers.anubis-wiki = {
          inherit image;
          autoStart = true;
          ports = [
            "127.0.0.1:8089:8080"
            "9089:9090"
          ];
          extraPodmanArgs = [ "--network=pasta:--map-host-loopback,169.254.1.2" ];
          volumes = [ "${wikiPolicy}:/data/cfg:ro" ];
          environment = {
            BIND = ":8080";
            TARGET = "http://169.254.1.2:8088";
            POLICY_FNAME = "/data/cfg/botPolicies.yaml";
            DIFFICULTY = 2;
            METRICS_BIND = ":9090";
          };
          extraConfig = hardening;
        };
      };
    };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    9084
    9085
    9089
  ];
}
