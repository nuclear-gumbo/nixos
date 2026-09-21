{
  home-manager.users.pangolin =
    { pkgs, ... }:
    let
      ratelimit = pkgs.writeText "ratelimit.yml" ''
        http:
          middlewares:
            public-ratelimit:
              rateLimit:
                average: 100
                burst: 200
      '';

      # named "default" so it also covers pangolin's http-provider routers, which
      # carry their own tls block and so ignore the entrypoint tls options
      tlsOptions = pkgs.writeText "tls.yml" ''
        tls:
          options:
            default:
              minVersion: VersionTLS12
              maxVersion: VersionTLS13
              # tls 1.2 only, 1.3 suites arent configurable
              cipherSuites:
                - TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
                - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
                - TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256
                - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
                - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
                - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256
              # no curvePreferences, gos default keeps p-256 and the pq hybrid group
              alpnProtocols:
                - h2
                - http/1.1
                - acme-tls/1
              # stops the self-signed default cert being served to ip/no-sni probes
              sniStrict: true
      '';

      securityHeaders = pkgs.writeText "security-headers.yml" ''
        http:
          middlewares:
            security-headers:
              headers:
                stsSeconds: 63072000
                stsIncludeSubdomains: true
                stsPreload: true
                forceSTSHeader: true
                contentTypeNosniff: true
                referrerPolicy: strict-origin-when-cross-origin
                hostsProxyHeaders:
                  - X-Forwarded-Host
                # no frame options or csp here, they would overwrite what the apps set
                customResponseHeaders:
                  Server: ""
                  X-Powered-By: ""
                  Permissions-Policy: "camera=(), microphone=(), geolocation=()"
      '';

      traefikConfig = pkgs.writeText "traefik_config.yml" ''
        api:
          insecure: false
          dashboard: false
        providers:
          http:
            endpoint: http://pangolin:3001/api/v1/traefik-config
            pollInterval: 5s
          file:
            directory: /rules
            watch: true
        experimental:
          plugins:
            badger:
              moduleName: github.com/fosrl/badger
              version: v1.5.0
            crowdsec-bouncer-traefik:
              moduleName: github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin
              version: v1.4.6
        log:
          level: INFO
          format: json
          maxSize: 100
          maxBackups: 3
          maxAge: 3
          compress: true
        accessLog:
          filePath: /var/log/traefik/access.log
          format: json
        certificatesResolvers:
          letsencrypt:
            acme:
              httpChallenge:
                entryPoint: web
              email: acme@gaialabs.space
              storage: /letsencrypt/acme.json
              caServer: https://acme-v02.api.letsencrypt.org/directory
        entryPoints:
          web:
            address: ':80'
            http:
              redirections:
                entryPoint:
                  to: websecure
                  scheme: https
                  permanent: true
          websecure:
            address: ':443'
            transport:
              respondingTimeouts:
                readTimeout: 30m
            http:
              middlewares:
                - public-ratelimit@file
                - security-headers@file
              tls:
                certResolver: letsencrypt
              encodedCharacters:
                allowEncodedSlash: true
                allowEncodedHash: true
        serversTransport:
          insecureSkipVerify: true
        ping:
          entryPoint: web
      '';

      netnsAliases = [
        "pangolin:127.0.0.1"
        "gerbil:127.0.0.1"
        "crowdsec:127.0.0.1"
        "middleware-manager:127.0.0.1"
      ];
      netnsOwner = {
        After = [ "podman-gerbil.service" ];
        Requires = [ "podman-gerbil.service" ];
        PartOf = [ "podman-gerbil.service" ];
      };
    in
    {
      home.stateVersion = "25.05";

      services.podman = {
        enable = true;

        settings.containers.containers.base_hosts_file = "none";

        containers.gerbil = {
          image = "docker.io/fosrl/gerbil@sha256:4d34b911fa1a68805e836d97778edd54a9ee692400ba0e49001cd78119804afb";
          autoStart = true;
          exec = "--reachableAt=http://gerbil:3004 --generateAndSaveKeyTo=/var/config/key --remoteConfig=http://pangolin:3001/api/v1/";
          ports = [
            "51820:51820/udp"
            "21820:21820/udp"
            "8443:443"
            "8080:80"
            "6060:6060"
            "6061:6061"
          ];
          volumes = [ "/var/lib/pangolin/config:/var/config" ];
          devices = [ "/dev/net/tun" ];
          extraPodmanArgs = [ "--network=pasta" ];
          extraConfig = {
            Container = {
              AddHost = netnsAliases;
              DropCapability = "ALL";
              AddCapability = "NET_ADMIN";
              NoNewPrivileges = true;
            };
            Service.Restart = "always";
            Unit.Upholds = [
              "podman-pangolin.service"
              "podman-traefik.service"
              "podman-crowdsec.service"
              "podman-crowdsec-export.service"
            ];
          };
        };

        containers.pangolin = {
          image = "docker.io/fosrl/pangolin:1.23@sha256:00cfb631097a819a0b6a65cf84e5d976a9f4a4fece533a59a984de374711f47a";
          autoStart = true;
          network = "container:gerbil";
          volumes = [ "/var/lib/pangolin/config:/app/config" ];
          extraConfig = {
            Container = {
              DropCapability = "ALL";
              NoNewPrivileges = true;
              HealthCmd = "curl -f http://localhost:3001/api/v1/";
              HealthInterval = "10s";
              HealthTimeout = "10s";
              HealthRetries = 15;
              Notify = "healthy";
            };
            Service.Restart = "always";
            Unit = netnsOwner;
          };
        };

        containers.traefik = {
          image = "docker.io/library/traefik:v3.7@sha256:24841fe2de7304c149343d877d2923b4c8800a38ba015dea9174c23b20e344a0";
          autoStart = true;
          network = "container:gerbil";
          exec = "--configFile=/etc/traefik/traefik_config.yml";
          volumes = [
            "/var/lib/pangolin/config/traefik:/etc/traefik:ro"
            "${traefikConfig}:/etc/traefik/traefik_config.yml:ro"
            "${ratelimit}:/rules/ratelimit.yml:ro"
            "${tlsOptions}:/rules/tls.yml:ro"
            "${securityHeaders}:/rules/security-headers.yml:ro"
            "/var/lib/pangolin/config/letsencrypt:/letsencrypt"
            "/var/lib/pangolin/config/traefik/logs:/var/log/traefik"
            "/var/lib/pangolin/config/traefik/rules:/rules"
            "/var/lib/pangolin/config/traefik/plugins-storage:/plugins-storage"
          ];
          extraConfig = {
            Container = {
              DropCapability = "ALL";
              AddCapability = "NET_BIND_SERVICE";
              NoNewPrivileges = true;
              ReadOnly = true;
            };
            Service.Restart = "always";
            Unit = {
              After = netnsOwner.After ++ [ "podman-pangolin.service" ];
              Requires = netnsOwner.Requires;
              PartOf = netnsOwner.PartOf;
              Wants = [ "podman-pangolin.service" ];
            };
          };
        };

        containers.crowdsec = {
          image = "docker.io/crowdsecurity/crowdsec:v1.8.1@sha256:0f2523fa61ef507f15d953045cface490cc880670c62f2755ced17524107f71a";
          autoStart = true;
          network = "container:gerbil";
          volumes = [
            "/var/lib/pangolin/config/crowdsec:/etc/crowdsec"
            "/var/lib/pangolin/config/crowdsec/db:/var/lib/crowdsec/data"
            "/var/lib/pangolin/config/traefik/logs:/var/log/traefik"
          ];
          environment = {
            GID = "1000";
            COLLECTIONS = "crowdsecurity/traefik crowdsecurity/appsec-virtual-patching crowdsecurity/appsec-generic-rules crowdsecurity/linux";
            PARSERS = "crowdsecurity/whitelists";
            ENROLL_INSTANCE_NAME = "pangolin-crowdsec";
            ENROLL_TAGS = "docker";
          };
          environmentFile = [ "/run/secrets/pangolin.crowdsec.env" ];
          extraConfig = {
            Container = {
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
              HealthInterval = "10s";
              HealthTimeout = "5s";
              HealthRetries = 3;
              HealthStartPeriod = "30s";
            };
            Service.Restart = "always";
            Unit = netnsOwner;
          };
        };

        containers.crowdsec-export = {
          image = "docker.io/library/python:3.14-alpine@sha256:9e9fde4d32eedce0b661d9ab91e826b62dddf28e928c230ec55f1866cac66b01";
          autoStart = true;
          network = "container:gerbil";
          exec = "python3 /app/lapi-export.py";
          volumes = [
            "${./lapi-export.py}:/app/lapi-export.py:ro"
            "/var/lib/pangolin/config/crowdsec/local_api_credentials.yaml:/etc/crowdsec/local_api_credentials.yaml:ro"
          ];
          environment = {
            LAPI_URL = "http://127.0.0.1:8080";
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
              After = netnsOwner.After ++ [ "podman-crowdsec.service" ];
              Requires = netnsOwner.Requires;
              PartOf = netnsOwner.PartOf;
              Wants = [ "podman-crowdsec.service" ];
            };
          };
        };

        containers.middleware-manager = {
          image = "docker.io/hhftechnology/middleware-manager@sha256:d739d47886631a04bd7e3c83d2c02799010d0a944c2f6256bfcd9b89f0b25487";
          autoStart = false;
          network = "container:gerbil";
          volumes = [
            "/var/lib/pangolin/data:/data"
            "/var/lib/pangolin/config/traefik/rules:/conf"
          ];
          environment = {
            PANGOLIN_API_URL = "http://pangolin:3001/api/v1";
            TRAEFIK_CONF_DIR = "/conf";
            DB_PATH = "/data/middleware.db";
            PORT = "3456";
          };
          extraConfig = {
            Container = {
              DropCapability = "ALL";
              NoNewPrivileges = true;
            };
            Service.Restart = "always";
            Unit = {
              After = netnsOwner.After ++ [ "podman-pangolin.service" ];
              Requires = netnsOwner.Requires;
              PartOf = netnsOwner.PartOf;
              Wants = [ "podman-pangolin.service" ];
            };
          };
        };
      };

      systemd.user.services.crowdsec-restart = {
        Unit.Description = "Restart crowdsec container";
        Service = {
          Type = "oneshot";
          ExecStart = "/run/current-system/sw/bin/systemctl --user restart podman-crowdsec.service";
        };
      };

      systemd.user.timers.crowdsec-restart = {
        Unit.Description = "Nightly crowdsec container restart at 4am Eastern";
        Timer = {
          OnCalendar = "*-*-* 04:00:00 America/New_York";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };

  sops.secrets."pangolin.crowdsec.env" = {
    sopsFile = ../../../../secrets/pangolin.crowdsec.env;
    format = "binary";
    owner = "pangolin";
    group = "pangolin";
    mode = "0400";
  };

  networking.firewall.allowedTCPPorts = [
    8080
    8443
  ];
  networking.firewall.allowedUDPPorts = [
    51820
    21820
  ];
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    3456
    6060
    6061
  ];

  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
    iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
    ip6tables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
    ip6tables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080 || true
    iptables -t nat -D PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443 || true
    ip6tables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080 || true
    ip6tables -t nat -D PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443 || true
  '';
}
