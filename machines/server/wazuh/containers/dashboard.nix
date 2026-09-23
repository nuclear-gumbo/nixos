{
  home-manager.users.wazuh =
    { pkgs, ... }:
    let
      dashboard = pkgs.writeText "opensearch_dashboards.yml" ''
        server.host: 0.0.0.0
        server.port: 5601
        opensearch.hosts: https://wazuh.indexer:9200
        opensearch.ssl.verificationMode: certificate
        opensearch.requestHeadersWhitelist: ["securitytenant","Authorization"]
        opensearch_security.multitenancy.enabled: false
        opensearch_security.readonly_mode.roles: ["kibana_read_only"]
        server.ssl.enabled: true
        server.ssl.key: "/certs/wazuh.dashboard-key.pem"
        server.ssl.certificate: "/certs/wazuh.dashboard.pem"
        opensearch.ssl.certificateAuthorities: ["/certs/root-ca.pem"]
        uiSettings.overrides.defaultRoute: /app/wz-home
        opensearch_security.cookie.ttl: 900000
        opensearch_security.session.ttl: 900000
        opensearch_security.session.keepalive: true
      '';
    in
    {
      services.podman = {
        volumes = {
          wazuh-dashboard-config = { };
          wazuh-dashboard-custom = { };
        };

        containers.wazuh-dashboard = {
          image = "docker.io/wazuh/wazuh-dashboard:4.14.8@sha256:b8e3d43711f29596dad12051a548abd0ed84692544f451d14ac2fc0c0b6a85c8";
          autoStart = true;
          network = "wazuh.network";
          networkAlias = [ "wazuh.dashboard" ];
          # rootless cant bind 443, so upstreams 443:5601 map is dropped
          ports = [ "5601:5601" ];
          volumes = [
            "wazuh-dashboard-config.volume:/usr/share/wazuh-dashboard/data/wazuh/config"
            "wazuh-dashboard-custom.volume:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/custom"
            "/var/lib/wazuh/certs:/certs:ro"
            "${dashboard}:/usr/share/wazuh-dashboard/config/opensearch_dashboards.yml:ro"
          ];
          environment = {
            WAZUH_API_URL = "https://wazuh.manager";
          };
          environmentFile = [ "/run/secrets/wazuh.env" ];
          extraConfig = {
            Container = {
              NoNewPrivileges = true;
            };
            Service.Restart = "always";
            Unit = {
              After = [
                "podman-wazuh-indexer.service"
                "podman-wazuh-manager.service"
              ];
              Wants = [
                "podman-wazuh-indexer.service"
                "podman-wazuh-manager.service"
              ];
            };
          };
        };
      };
    };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 5601 ];

  sops.secrets."wazuh.env" = {
    sopsFile = ../../../../secrets/wazuh.env;
    format = "binary";
    owner = "wazuh";
    group = "wazuh";
    mode = "0400";
  };
}
