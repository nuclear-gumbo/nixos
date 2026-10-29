{
  home-manager.users.crowdsec =
    { pkgs, ... }:
    let
      acquis = pkgs.writeText "traefik.yaml" ''
        filenames:
          - /var/log/traefik/access.log
        labels:
          type: traefik
      '';

      appsecAcquis = pkgs.writeText "appsec.yaml" ''
        source: appsec
        listen_addr: 0.0.0.0:7422
        appsec_config: crowdsecurity/appsec-default
        labels:
          type: appsec
      '';

      whitelist = pkgs.writeText "searx-space-whitelist.yaml" ''
        name: srv-n2/searx-space-checker
        description: "never ban the searx.space checker"
        whitelist:
          reason: "searx.space checker"
          cidr:
            - "167.235.158.251/32"
            - "2a01:4f8:1c1c:8fc2::/64"
      '';

      # dont ban matrix traffic
      matrixWhitelist = pkgs.writeText "matrix-whitelist.yaml" ''
        name: srv-n2/matrix-api
        description: "never ban on matrix client or federation API traffic"
        whitelist:
          reason: "matrix api"
          expression:
            - "evt.Parsed.request startsWith '/_matrix/'"
      '';

      profiles = pkgs.writeText "profiles.yaml" ''
        name: default_ip_remediation
        filters:
          - Alert.Remediation == true && Alert.GetScope() == "Ip"
        decisions:
          - type: ban
            duration: 4h
        on_success: break
        ---
        name: default_range_remediation
        filters:
          - Alert.Remediation == true && Alert.GetScope() == "Range"
        decisions:
          - type: ban
            duration: 4h
        on_success: break
      '';
    in
    {
      home.stateVersion = "25.05";

      services.podman = {
        enable = true;

        networks.crowdsec = { };

        containers.crowdsec = {
          image = "docker.io/crowdsecurity/crowdsec:v1.8.2@sha256:65b74942f7e7ed5c60fde4ac15fc4ba715904c398c8b16dd451f4907d90347d4";
          autoStart = true;
          network = "crowdsec.network";
          networkAlias = [ "crowdsec" ];
          ports = [
            "6060:6060"
            "127.0.0.1:8080:8080"
            "127.0.0.1:7422:7422"
          ];
          volumes = [
            "/var/lib/crowdsec/etc:/etc/crowdsec"
            "/var/lib/crowdsec/data:/var/lib/crowdsec/data"
            "/var/log/traefik:/var/log/traefik:ro"
            "${acquis}:/etc/crowdsec/acquis.d/traefik.yaml:ro"
            "${appsecAcquis}:/etc/crowdsec/acquis.d/appsec.yaml:ro"
            "${profiles}:/etc/crowdsec/profiles.yaml:ro"
            "${whitelist}:/etc/crowdsec/parsers/s02-enrich/searx-space-whitelist.yaml:ro"
            "${matrixWhitelist}:/etc/crowdsec/parsers/s02-enrich/matrix-whitelist.yaml:ro"
          ];
          environment = {
            COLLECTIONS = "crowdsecurity/traefik crowdsecurity/appsec-virtual-patching crowdsecurity/appsec-generic-rules";
            DISABLE_ONLINE_API = "false";
            ENROLL_INSTANCE_NAME = "srv-n2-crowdsec";
            ENROLL_TAGS = "public traefik anubis searxng privatebin";
          };
          environmentFile = [ "/run/secrets/crowdsec.env" ];
          extraConfig = {
            Container = {
              # carries weblogs membership into the userns to read traefik's log
              GroupAdd = "keep-groups";
              DropCapability = "ALL";
              AddCapability = [
                "CHOWN"
                "DAC_OVERRIDE"
                "FOWNER"
                "SETGID"
                "SETUID"
              ];
              NoNewPrivileges = true;
              HealthCmd = "cscli lapi status";
              HealthInterval = "30s";
              HealthTimeout = "5s";
              HealthRetries = 3;
              HealthStartPeriod = "30s";
            };
            Service.Restart = "always";
          };
        };

        containers.crowdsec-export = {
          image = "docker.io/library/python:3.15-alpine@sha256:0aa144e9ec2ae8fd80dfd94070ef3e432a0df17b6e5e0091dc05323974ce9913";
          autoStart = true;
          network = "crowdsec.network";
          ports = [ "6061:6061" ];
          exec = "python3 /app/lapi-export.py";
          volumes = [
            "${../../pangolin/containers/lapi-export.py}:/app/lapi-export.py:ro"
            "/var/lib/crowdsec/etc/local_api_credentials.yaml:/etc/crowdsec/local_api_credentials.yaml:ro"
          ];
          environment = {
            LAPI_URL = "http://crowdsec:8080";
            PYTHONDONTWRITEBYTECODE = "1";
            PYTHONUNBUFFERED = "1";
          };
          extraConfig = {
            Container = {
              DropCapability = "ALL";
              NoNewPrivileges = true;
              ReadOnly = true;
              HealthCmd = "python3 -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:6061/healthz', timeout=10)\"";
              HealthInterval = "60s";
              HealthTimeout = "15s";
              HealthRetries = 3;
              HealthStartPeriod = "30s";
            };
            Service.Restart = "always";
            Unit = {
              After = [ "podman-crowdsec.service" ];
              Wants = [ "podman-crowdsec.service" ];
            };
          };
        };
      };
    };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    6060
    6061
  ];

  sops.secrets."crowdsec.env" = {
    sopsFile = ../../../../secrets/srv-n2.crowdsec.env;
    format = "binary";
    owner = "crowdsec";
    group = "crowdsec";
    mode = "0400";
  };
}
