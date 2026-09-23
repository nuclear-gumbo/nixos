{
  home-manager.users.wazuh =
    { pkgs, ... }:
    let
      opensearch = pkgs.writeText "opensearch.yml" ''
        network.host: "0.0.0.0"
        node.name: "wazuh.indexer"
        cluster.name: "wazuh-cluster"
        path.data: /var/lib/wazuh-indexer
        path.logs: /var/log/wazuh-indexer
        discovery.type: single-node
        compatibility.override_main_response_version: true
        plugins.security.ssl.http.pemcert_filepath: /usr/share/wazuh-indexer/config/certs/wazuh.indexer.pem
        plugins.security.ssl.http.pemkey_filepath: /usr/share/wazuh-indexer/config/certs/wazuh.indexer-key.pem
        plugins.security.ssl.http.pemtrustedcas_filepath: /usr/share/wazuh-indexer/config/certs/root-ca.pem
        plugins.security.ssl.transport.pemcert_filepath: /usr/share/wazuh-indexer/config/certs/wazuh.indexer.pem
        plugins.security.ssl.transport.pemkey_filepath: /usr/share/wazuh-indexer/config/certs/wazuh.indexer-key.pem
        plugins.security.ssl.transport.pemtrustedcas_filepath: /usr/share/wazuh-indexer/config/certs/root-ca.pem
        plugins.security.ssl.http.enabled: true
        plugins.security.ssl.transport.enforce_hostname_verification: false
        plugins.security.ssl.transport.resolve_hostname: false
        plugins.security.ssl.http.enabled_ciphers:
          - "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
          - "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
          - "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
          - "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
        plugins.security.ssl.http.enabled_protocols:
          - "TLSv1.2"
        plugins.security.authcz.admin_dn:
          - "CN=admin,OU=Wazuh,O=Wazuh,L=California,C=US"
        plugins.security.check_snapshot_restore_write_privileges: true
        plugins.security.enable_snapshot_restore_privilege: true
        plugins.security.nodes_dn:
          - "CN=wazuh.indexer,OU=Wazuh,O=Wazuh,L=California,C=US"
        plugins.security.restapi.roles_enabled:
          - "all_access"
          - "security_rest_api_access"
        plugins.security.system_indices.enabled: true
        plugins.security.system_indices.indices: [".opendistro-alerting-config", ".opendistro-alerting-alert*", ".opendistro-anomaly-results*", ".opendistro-anomaly-detector*", ".opendistro-anomaly-checkpoints", ".opendistro-anomaly-detection-state", ".opendistro-reports-*", ".opendistro-notifications-*", ".opendistro-notebooks", ".opensearch-observability", ".opendistro-asynchronous-search-response*", ".replication-metadata-store"]
        plugins.security.allow_default_init_securityindex: true
        cluster.routing.allocation.disk.threshold_enabled: false
      '';
    in
    {
      services.podman = {
        volumes.wazuh-indexer-data = { };

        containers.wazuh-indexer = {
          image = "docker.io/wazuh/wazuh-indexer:4.14.8@sha256:929179d223dc44e40c2e5c8bdbd1df19c6f68ab8f4ac255dfce98d92ee831a17";
          autoStart = true;
          network = "wazuh.network";
          # the generated certs carry CN=wazuh.indexer, so the alias has to match
          networkAlias = [ "wazuh.indexer" ];
          volumes = [
            "wazuh-indexer-data.volume:/var/lib/wazuh-indexer"
            # javas security manager only grants reads under path.conf
            "/var/lib/wazuh/certs:/usr/share/wazuh-indexer/config/certs:ro"
            "${opensearch}:/usr/share/wazuh-indexer/config/opensearch.yml:ro"
            "/run/secrets/wazuh.internal-users.yml:/usr/share/wazuh-indexer/config/opensearch-security/internal_users.yml:ro"
          ];
          environment = {
            OPENSEARCH_JAVA_OPTS = "-Xms1g -Xmx1g";
          };
          extraConfig = {
            Container = {
              NoNewPrivileges = true;
            };
            Service = {
              Restart = "always";
              LimitNOFILE = 65536;
            };
            Unit = {
              After = [ "podman-wazuh-certs.service" ];
              Requires = [ "podman-wazuh-certs.service" ];
            };
          };
        };
      };
    };

  # the indexer runs as uid 1000 inside the userns, so root-only wont read
  sops.secrets."wazuh.internal-users.yml" = {
    sopsFile = ../../../../secrets/wazuh.internal-users.yml;
    format = "binary";
    owner = "wazuh";
    group = "wazuh";
    mode = "0444";
  };
}
