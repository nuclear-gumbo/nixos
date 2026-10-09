{
  home-manager.users.anubis =
    { pkgs, ... }:
    let
      image = "ghcr.io/techarohq/anubis:v1.28.1@sha256:1744c03a918160a28b0d2e8c1656de6585f4071b30b4c3b0d51d02282c9b7c25";

      # srv-n2's apex-scoped cookie collides with the default name
      cookiePrefix = "anubis-status";

      # challenge the page only
      policy = pkgs.writeTextDir "botPolicies.yaml" ''
        bots:
          - import: (data)/meta/default-config.yaml

          - name: status-page-assets
            action: ALLOW
            expression:
              any:
                - 'path == "/serviceWorker.js"'
                - 'path == "/favicon.ico"'
                - 'path == "/icon.svg"'
                - 'path == "/manifest.json"'
                - 'path.startsWith("/assets/")'
                - 'path.startsWith("/upload/")'
                - 'path.startsWith("/api/status-page/")'
                - 'path.startsWith("/api/badge/")'
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

        containers.anubis-status-libresearch = {
          inherit image;
          autoStart = true;
          ports = [ "127.0.0.1:8088:8080" ];
          extraPodmanArgs = [ "--network=pasta:--map-host-loopback,169.254.1.2" ];
          volumes = [ "${policy}:/data/cfg:ro" ];
          environment = {
            BIND = ":8080";
            TARGET = "http://169.254.1.2:3003";
            POLICY_FNAME = "/data/cfg/botPolicies.yaml";
            COOKIE_PREFIX = cookiePrefix;
            DIFFICULTY = 4;
          };
          extraConfig = hardening;
        };

        containers.anubis-status-pasted = {
          inherit image;
          autoStart = true;
          ports = [ "127.0.0.1:8089:8080" ];
          extraPodmanArgs = [ "--network=pasta:--map-host-loopback,169.254.1.2" ];
          volumes = [ "${policy}:/data/cfg:ro" ];
          environment = {
            BIND = ":8080";
            TARGET = "http://169.254.1.2:3004";
            POLICY_FNAME = "/data/cfg/botPolicies.yaml";
            COOKIE_PREFIX = cookiePrefix;
            DIFFICULTY = 4;
          };
          extraConfig = hardening;
        };
      };
    };
}
