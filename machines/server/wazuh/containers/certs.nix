{
  # apply tmpfiles perm every boot/switch
  systemd.tmpfiles.rules = [ "d /var/lib/wazuh/certs 0755 wazuh wazuh -" ];

  home-manager.users.wazuh =
    { pkgs, ... }:
    let
      certs = pkgs.writeText "certs.yml" ''
        nodes:
          indexer:
            - name: wazuh.indexer
              ip: wazuh.indexer
          server:
            - name: wazuh.manager
              ip: wazuh.manager
          dashboard:
            - name: wazuh.dashboard
              ip: wazuh.dashboard
      '';
    in
    {
      services.podman.containers.wazuh-certs = {
        image = "docker.io/wazuh/wazuh-certs-generator:0.0.5@sha256:1be9f9abfb6a37ac7bd3d6d707e1b43589c2b81b23c01a46992e93832795abf9";
        autoStart = true;
        entrypoint = "/bin/bash";
        # loosen perms for userspace container
        exec = "-c \"/entrypoint.sh && chmod 755 /certificates\"";
        volumes = [
          "/var/lib/wazuh/certs:/certificates"
          "${certs}:/config/certs.yml:ro"
        ];
        environment = {
          CERT_TOOL_VERSION = "4.14";
        };
        extraConfig = {
          Container = {
            NoNewPrivileges = true;
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = "yes";
            Restart = "no";
          };
          # regenerating would invalidate every cert
          Unit.ConditionPathExists = "!/var/lib/wazuh/certs/root-ca.pem";
        };
      };
    };
}
