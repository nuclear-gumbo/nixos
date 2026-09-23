{
  home-manager.users.wazuh = { ... }: {
    services.podman = {
      volumes = {
        wazuh-api-configuration = { };
        wazuh-etc = { };
        wazuh-logs = { };
        wazuh-queue = { };
        wazuh-var-multigroups = { };
        wazuh-integrations = { };
        wazuh-active-response = { };
        wazuh-agentless = { };
        wazuh-wodles = { };
        wazuh-filebeat-etc = { };
        wazuh-filebeat-var = { };
      };

      containers.wazuh-manager = {
        image = "docker.io/wazuh/wazuh-manager:4.14.8@sha256:6b53d4cc5c013b08157471d11f7a7c2c45f9e8238f3958e3b2f04ec1773ecbd4";
        autoStart = true;
        network = "wazuh.network";
        networkAlias = [ "wazuh.manager" ];
        ports = [
          "1514:1514"
          "1515:1515"
          "55000:55000"
        ];
        volumes = [
          "wazuh-api-configuration.volume:/var/ossec/api/configuration"
          "wazuh-etc.volume:/var/ossec/etc"
          "wazuh-logs.volume:/var/ossec/logs"
          "wazuh-queue.volume:/var/ossec/queue"
          "wazuh-var-multigroups.volume:/var/ossec/var/multigroups"
          "wazuh-integrations.volume:/var/ossec/integrations"
          "wazuh-active-response.volume:/var/ossec/active-response/bin"
          "wazuh-agentless.volume:/var/ossec/agentless"
          "wazuh-wodles.volume:/var/ossec/wodles"
          "wazuh-filebeat-etc.volume:/etc/filebeat"
          "wazuh-filebeat-var.volume:/var/lib/filebeat"
          "/var/lib/wazuh/certs:/certs:ro"
          "${./ossec.conf}:/wazuh-config-mount/etc/ossec.conf:ro"
        ];
        # INDEXER_URL is left unset, the images filebeat.yml already points at wazuh.indexer
        environment = {
          FILEBEAT_SSL_VERIFICATION_MODE = "full";
          SSL_CERTIFICATE_AUTHORITIES = "/certs/root-ca-manager.pem";
          SSL_CERTIFICATE = "/certs/wazuh.manager.pem";
          SSL_KEY = "/certs/wazuh.manager-key.pem";
        };
        environmentFile = [ "/run/secrets/wazuh.env" ];
        extraConfig = {
          Service = {
            Restart = "always";
            LimitNOFILE = 655360;
          };
          Unit = {
            After = [ "podman-wazuh-indexer.service" ];
            Wants = [ "podman-wazuh-indexer.service" ];
          };
        };
      };
    };
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    1514
    1515
    55000
  ];
}
