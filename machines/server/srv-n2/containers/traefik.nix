{
  home-manager.users.traefik =
    { pkgs, ... }:
    let
      # yaegi interprets this from disk, so the official image stays unmodified
      bouncer = pkgs.fetchFromGitHub {
        owner = "maxlerebourg";
        repo = "crowdsec-bouncer-traefik-plugin";
        tag = "v1.7.1";
        hash = "sha256-hefOKDVsBxn+rCAylPHqbCNfPMbU/vtO4QpiftIPcUU=";
      };

      static = pkgs.writeText "traefik.yml" ''
        global:
          checkNewVersion: false
          sendAnonymousUsage: false

        entryPoints:
          web:
            address: ":80"
            http:
              redirections:
                entryPoint:
                  to: websecure
                  scheme: https
          websecure:
            address: ":443"
            http:
              tls:
                certResolver: le
            http3: {}

        certificatesResolvers:
          le:
            acme:
              email: acme@gaialabs.space
              storage: /acme/acme.json
              tlsChallenge: {}

        providers:
          file:
            directory: /etc/traefik/dynamic
            watch: true

        experimental:
          localPlugins:
            bouncer:
              moduleName: github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin

        accessLog:
          filePath: /var/log/traefik/access.log
          format: json
          fields:
            queryParameters:
              defaultMode: drop

        log:
          level: ERROR

        api:
          dashboard: false
      '';

      csp = "upgrade-insecure-requests; default-src 'none'; script-src 'self'; worker-src 'self' blob:; style-src 'self' 'unsafe-inline'; form-action 'self' https:; font-src 'self'; frame-ancestors 'self'; base-uri 'self'; connect-src 'self'; img-src * data:; frame-src https:;";

      # privatebin's own policy, plus inline styles for anubis' interstitial, which sends none
      pastedCsp = "default-src 'none'; base-uri 'self'; form-action 'none'; manifest-src 'self'; connect-src * blob:; script-src 'self' 'wasm-unsafe-eval'; worker-src 'self' blob:; style-src 'self' 'unsafe-inline'; font-src 'self'; frame-ancestors 'self'; frame-src blob:; img-src 'self' data: blob:; media-src blob:; object-src blob:; sandbox allow-same-origin allow-scripts allow-forms allow-modals allow-downloads";

      # 'wasm-unsafe-eval' and blob workers are anubis' proof of work
      wikiCsp = "upgrade-insecure-requests; default-src 'none'; base-uri 'self'; form-action 'none'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval'; worker-src 'self' blob:; style-src 'self' 'unsafe-inline'; font-src 'self'; img-src 'self' data:; connect-src 'self'; manifest-src 'self';";

      dynamic = pkgs.writeTextDir "routers.yml" ''
        http:
          middlewares:
            hardening:
              headers:
                stsSeconds: 31536000
                stsIncludeSubdomains: true
                stsPreload: true
                contentTypeNosniff: true
                referrerPolicy: no-referrer
                permissionsPolicy: "geolocation=(), microphone=(), camera=()"
                customResponseHeaders:
                  Cross-Origin-Opener-Policy: same-origin
                  Server: ""

            libresearch-headers:
              headers:
                frameDeny: true
                contentSecurityPolicy: "${csp}"

            pasted-headers:
              headers:
                customFrameOptionsValue: SAMEORIGIN
                contentSecurityPolicy: "${pastedCsp}"

            wiki-headers:
              headers:
                frameDeny: true
                contentSecurityPolicy: "${wikiCsp}"

            matrix-ratelimit:
              rateLimit:
                average: 50
                burst: 100

            outage-libresearch:
              errors:
                status: [ "500-599" ]
                service: outage
                query: "/libresearch.html"

            outage-pasted:
              errors:
                status: [ "500-599" ]
                service: outage
                query: "/pasted.html"

          routers:
            libresearch:
              rule: "Host(`libresearch.space`) || Host(`www.libresearch.space`)"
              entryPoints: [ websecure ]
              middlewares: [ crowdsec, hardening, libresearch-headers, outage-libresearch ]
              service: libresearch
            pasted:
              rule: "Host(`pasted.space`) || Host(`www.pasted.space`)"
              entryPoints: [ websecure ]
              middlewares: [ crowdsec, hardening, pasted-headers, outage-pasted ]
              service: pasted

          services:
            libresearch:
              loadBalancer:
                servers:
                  - url: "http://169.254.1.2:8084"
            pasted:
              loadBalancer:
                servers:
                  - url: "http://169.254.1.2:8085"
            outage:
              loadBalancer:
                servers:
                  - url: "http://169.254.1.2:8087"

        tls:
          options:
            default:
              minVersion: VersionTLS12
              curvePreferences: [ X25519, CurveP256 ]
              cipherSuites:
                - TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
                - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
                - TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
                - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
                - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
                - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
      '';
    in
    {
      home.stateVersion = "25.05";

      services.podman = {
        enable = true;

        containers.traefik = {
          image = "docker.io/library/traefik:v3.7@sha256:24841fe2de7304c149343d877d2923b4c8800a38ba015dea9174c23b20e344a0";
          autoStart = true;
          ports = [
            "8081:80"
            "8443:443"
            "8443:443/udp"
          ];
          extraPodmanArgs = [ "--network=pasta:--map-host-loopback,169.254.1.2" ];
          volumes = [
            "${static}:/etc/traefik/traefik.yml:ro"
            "${dynamic}/routers.yml:/etc/traefik/dynamic/routers.yml:ro"
            "/run/secrets/traefik-crowdsec.yml:/etc/traefik/dynamic/crowdsec.yml:ro"
            "/run/secrets/traefik-tuwunel.yml:/etc/traefik/dynamic/tuwunel.yml:ro"
            "/run/secrets/traefik-wiki.yml:/etc/traefik/dynamic/wiki.yml:ro"
            "${bouncer}:/plugins-local/src/github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin:ro"
            "/var/lib/traefik/acme:/acme"
            "/var/log/traefik:/var/log/traefik"
          ];
          extraConfig = {
            Container = {
              DropCapability = "ALL";
              AddCapability = [ "NET_BIND_SERVICE" ];
              NoNewPrivileges = true;
              ReadOnly = true;
              Tmpfs = "/tmp";
            };
            Service.Restart = "always";
          };
        };
      };
    };

  services.logrotate.settings."/var/log/traefik/access.log" = {
    size = "50M";
    rotate = 5;
    copytruncate = true;
    missingok = true;
    notifempty = true;
  };

  networking.firewall.allowedTCPPorts = [
    8081
    8443
  ];
  networking.firewall.allowedUDPPorts = [ 8443 ];

  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8081
    iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
    iptables -t nat -A PREROUTING -p udp --dport 443 -j REDIRECT --to-port 8443
    ip6tables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8081
    ip6tables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
    ip6tables -t nat -A PREROUTING -p udp --dport 443 -j REDIRECT --to-port 8443

    # PREROUTING misses local traffic, so the homeservers cant federate
    iptables -t nat -A OUTPUT -d 51.79.74.69 -p tcp --dport 443 -j DNAT --to-destination 51.79.74.69:8443
    ip6tables -t nat -A OUTPUT -d 2607:5300:205:200::6e98 -p tcp --dport 443 -j DNAT --to-destination [2607:5300:205:200::6e98]:8443
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8081 || true
    iptables -t nat -D PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443 || true
    iptables -t nat -D PREROUTING -p udp --dport 443 -j REDIRECT --to-port 8443 || true
    ip6tables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8081 || true
    ip6tables -t nat -D PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443 || true
    ip6tables -t nat -D PREROUTING -p udp --dport 443 -j REDIRECT --to-port 8443 || true
    iptables -t nat -D OUTPUT -d 51.79.74.69 -p tcp --dport 443 -j DNAT --to-destination 51.79.74.69:8443 || true
    ip6tables -t nat -D OUTPUT -d 2607:5300:205:200::6e98 -p tcp --dport 443 -j DNAT --to-destination [2607:5300:205:200::6e98]:8443 || true
  '';

  sops.secrets."traefik-crowdsec.yml" = {
    sopsFile = ../../../../secrets/srv-n2.traefik-crowdsec.yml;
    format = "binary";
    owner = "traefik";
    group = "traefik";
    mode = "0400";
  };

  sops.secrets."traefik-tuwunel.yml" = {
    sopsFile = ../../../../secrets/srv-n2.traefik-tuwunel.yml;
    format = "binary";
    owner = "traefik";
    group = "traefik";
    mode = "0400";
  };

  sops.secrets."traefik-wiki.yml" = {
    sopsFile = ../../../../secrets/srv-n2.traefik-wiki.yml;
    format = "binary";
    owner = "traefik";
    group = "traefik";
    mode = "0400";
  };
}
