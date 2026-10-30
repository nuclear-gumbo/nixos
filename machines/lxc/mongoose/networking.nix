{ config, pkgs, ... }:
{
  networking.wg-quick.interfaces.wg0 = {
    autostart = true;
    configFile = "/run/secrets/wg0.conf";
  };

  environment.systemPackages = with pkgs; [
    libnatpmp
  ];

  sops.secrets."wg0.conf" = {
    sopsFile = ../../../secrets/mongoose.wg0;
    format = "binary";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  networking.firewall.interfaces.eth0.allowedTCPPorts = [ 8080 ];

  # wg-quicks tunnel sends replies to other vlans out wg0, so traffic sourced from the lan address stays on main
  systemd.network.networks."99-ethernet-default-dhcp".routingPolicyRules = [
    {
      From = "10.10.1.0/24";
      Table = "main";
      Priority = 100;
    }
  ];

  server.killswitch = {
    enable = true;
    uid = config.users.users.gumbo.uid;
    vpnInterface = "wg0";
    lanInterface = "eth0";
  };
}
