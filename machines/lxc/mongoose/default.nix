{ lib, ... }:
{
  imports = [
    ../../../modules/baseline.lxc.nix
    ./containers
    ./networking.nix
  ];

  networking.hostName = "mongoose";

  boot.tmp.cleanOnBoot = true;

  # egress through wg0, no tailnet and no comin/cache
  services.tailscale.enable = lib.mkForce false;
  server.cd.enable = false;
}
