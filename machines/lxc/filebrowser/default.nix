{
  imports = [
    ../../../modules/baseline.lxc.nix
    ./containers
  ];

  networking.hostName = "filebrowser";

  server.cache.enable = true;
}
