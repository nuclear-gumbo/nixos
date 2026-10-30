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

  server.killswitch = {
    enable = true;
    uid = config.users.users.gumbo.uid;
    vpnInterface = "wg0";
    lanInterface = "eth0";
  };
}
