{
  home-manager.users.grafana =
    { pkgs, ... }:
    let
      prometheusConfig = pkgs.writeText "prometheus.yml" ''
        global:
          scrape_interval: 30s
          scrape_timeout: 10s

        scrape_configs:
          - job_name: crowdsec
            static_configs:
              - targets:
                  - 100.69.69.201:6060
                labels:
                  host: pangolin

          - job_name: crowdsec-srv-n2
            static_configs:
              - targets:
                  - 100.69.69.215:6060
                labels:
                  host: srv-n2

          - job_name: anubis-libresearch
            static_configs:
              - targets:
                  - 100.69.69.215:9084
                labels:
                  host: srv-n2
                  site: libresearch.space

          - job_name: anubis-pasted
            static_configs:
              - targets:
                  - 100.69.69.215:9085
                labels:
                  host: srv-n2
                  site: pasted.space

          - job_name: anubis-wiki
            static_configs:
              - targets:
                  - 100.69.69.215:9089
                labels:
                  host: srv-n2
                  site: wiki

          - job_name: harmonia
            static_configs:
              - targets:
                  - 100.69.69.219:5000
                labels:
                  host: runner

          - job_name: prometheus
            static_configs:
              - targets:
                  - localhost:9090
      '';

      infinityPlugin = pkgs.fetchzip {
        url = "https://grafana.com/api/plugins/yesoreyeram-infinity-datasource/versions/3.10.1/download?os=linux&arch=amd64";
        extension = "zip";
        hash = "sha256-/weiN7dtfJaqywfGpyg1k5rDJlDq6OX37WlDeK3U/zA=";
      };

      grafanaDatasources = pkgs.writeText "datasources.yml" ''
        apiVersion: 1
        datasources:
          - name: Prometheus
            uid: prometheus
            type: prometheus
            access: proxy
            url: http://prometheus:9090
            isDefault: true
            editable: false
          - name: CrowdSec LAPI
            uid: crowdsec-lapi
            type: yesoreyeram-infinity-datasource
            access: proxy
            url: http://100.69.69.201:6061
            isDefault: false
            editable: false
            jsonData:
              allowedHosts:
                - http://100.69.69.201:6061
          - name: CrowdSec LAPI srv-n2
            uid: crowdsec-lapi-srv-n2
            type: yesoreyeram-infinity-datasource
            access: proxy
            url: http://100.69.69.215:6061
            isDefault: false
            editable: false
            jsonData:
              allowedHosts:
                - http://100.69.69.215:6061
      '';

      grafanaDashboardProvider = pkgs.writeText "dashboards.yml" ''
        apiVersion: 1
        providers:
          - name: security
            folder: Security
            type: file
            options:
              path: /etc/grafana/dashboards
          - name: infra
            folder: Infra
            type: file
            options:
              path: /etc/grafana/dashboards-infra
      '';
    in
    {
      home.stateVersion = "25.05";

      services.podman = {
        enable = true;

        networks.monitoring = { };

        containers.prometheus = {
          image = "docker.io/prom/prometheus:v3.15.0@sha256:efd719c99d83b060d9daefdcf00360461adf279f45ef5391f8d111892118753e";
          autoStart = true;
          network = "monitoring.network";
          networkAlias = [ "prometheus" ];
          exec = "--config.file=/etc/prometheus/prometheus.yml --storage.tsdb.retention.time=90d";
          volumes = [
            "${prometheusConfig}:/etc/prometheus/prometheus.yml:ro"
            "/var/lib/grafana/prometheus:/prometheus:U"
          ];
          extraConfig = {
            Container = {
              DropCapability = "ALL";
              NoNewPrivileges = true;
              ReadOnly = true;
            };
            Service.Restart = "always";
          };
        };

        containers.grafana = {
          image = "docker.io/grafana/grafana@sha256:ac461fb352abc50da10a51c7d02462e9c05488f11f53f14b3ad79a8145f638a0";
          autoStart = true;
          network = "monitoring.network";
          ports = [ "127.0.0.1:3030:3000" ];
          volumes = [
            "${grafanaDatasources}:/etc/grafana/provisioning/datasources/datasources.yml:ro"
            "${grafanaDashboardProvider}:/etc/grafana/provisioning/dashboards/dashboards.yml:ro"
            "${./crowdsec-dashboard.json}:/etc/grafana/dashboards/crowdsec.json:ro"
            "${./crowdsec-srv-n2-dashboard.json}:/etc/grafana/dashboards/crowdsec-srv-n2.json:ro"
            "${./harmonia-dashboard.json}:/etc/grafana/dashboards-infra/harmonia.json:ro"
            "/var/lib/grafana/data:/var/lib/grafana:U"
            "${infinityPlugin}:/var/lib/grafana/plugins/yesoreyeram-infinity-datasource:ro"
          ];
          environment = {
            GF_ANALYTICS_REPORTING_ENABLED = "false";
            GF_ANALYTICS_CHECK_FOR_UPDATES = "false";
            GF_SECURITY_DISABLE_GRAVATAR = "true";
            GF_USERS_ALLOW_SIGN_UP = "false";
            GF_AUTH_OAUTH_ALLOW_INSECURE_EMAIL_LOOKUP = "true";
          };
          environmentFile = [ "/run/secrets/grafana.env" ];
          extraConfig = {
            Container = {
              DropCapability = "ALL";
              NoNewPrivileges = true;
              ReadOnly = true;
            };
            Service.Restart = "always";
            Unit = {
              After = [ "podman-prometheus.service" ];
              Wants = [ "podman-prometheus.service" ];
            };
          };
        };
      };
    };

  sops.secrets."grafana.env" = {
    sopsFile = ../../../../../secrets/srv-n1.grafana.env;
    format = "binary";
    owner = "grafana";
    group = "grafana";
    mode = "0400";
  };
}
