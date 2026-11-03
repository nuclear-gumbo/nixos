{
  home-manager.users.adguard = { ... }: {
    home.stateVersion = "25.05";

    services.podman = {
      enable = true;
      containers.adguard = {
        image = "docker.io/adguard/adguardhome:v0.107.80@sha256:e2e1b48c832f7705be915873f95de0d5114de573736441d7f2923a8a6293027c";
        autoStart = true;
        ports = [
          "100.69.69.210:5353:53/tcp"
          "100.69.69.210:5353:53/udp"
          "[fd7a:115c:a1e0::7e36:ab2a]:5353:53/tcp"
          "[fd7a:115c:a1e0::7e36:ab2a]:5353:53/udp"
          "100.69.69.210:8080:80"
          "[fd7a:115c:a1e0::7e36:ab2a]:8080:80"
        ];
        volumes = [
          "/var/lib/adguard/work:/opt/adguardhome/work:Z"
          "/var/lib/adguard/conf:/opt/adguardhome/conf:Z"
        ];
        extraConfig = {
          Container = {
            AddCapability = "NET_BIND_SERVICE";
            DropCapability = "ALL";
            NoNewPrivileges = true;
          };
          Service.Restart = "always";
        };
      };
    };
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 8080 ];

  # Redirect traffic from 5353 to 53 since adguard cant bind to a privileged port
  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -d 100.69.69.210 -p udp --dport 53 -j REDIRECT --to-port 5353
    iptables -t nat -A PREROUTING -d 100.69.69.210 -p tcp --dport 53 -j REDIRECT --to-port 5353
    ip6tables -t nat -A PREROUTING -d fd7a:115c:a1e0::7e36:ab2a -p udp --dport 53 -j REDIRECT --to-port 5353
    ip6tables -t nat -A PREROUTING -d fd7a:115c:a1e0::7e36:ab2a -p tcp --dport 53 -j REDIRECT --to-port 5353
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t nat -D PREROUTING -d 100.69.69.210 -p udp --dport 53 -j REDIRECT --to-port 5353 || true
    iptables -t nat -D PREROUTING -d 100.69.69.210 -p tcp --dport 53 -j REDIRECT --to-port 5353 || true
    ip6tables -t nat -D PREROUTING -d fd7a:115c:a1e0::7e36:ab2a -p udp --dport 53 -j REDIRECT --to-port 5353 || true
    ip6tables -t nat -D PREROUTING -d fd7a:115c:a1e0::7e36:ab2a -p tcp --dport 53 -j REDIRECT --to-port 5353 || true
  '';
}
