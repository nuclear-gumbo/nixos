{
  fileSystems."/mnt/manga" = {
    device = "10.10.1.100:/mediapool/media/manga";
    fsType = "nfs";
    options = [
      "noatime"
      "nofail"
    ];
  };
  fileSystems."/mnt/photos" = {
    device = "10.10.1.100:/mediapool/media/photos";
    fsType = "nfs";
    options = [
      "noatime"
      "nofail"
    ];
  };
  fileSystems."/mnt/music" = {
    device = "10.10.1.100:/mediapool/media/music/lossless";
    fsType = "nfs";
    options = [
      "noatime"
      "nofail"
    ];
  };

  # stop rootless container user managers before nfs unmounts and the network goes down
  systemd.services."user@" = {
    overrideStrategy = "asDropin";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "remote-fs.target" ];
  };
}
