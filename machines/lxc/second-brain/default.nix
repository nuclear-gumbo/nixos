{ inputs, ... }:

{
  imports = [
    ../../../modules/baseline.lxc.nix
    inputs.second-brain.nixosModules.default
  ];

  networking.hostName = "second-brain";

  server.cache.enable = true;
  # no sops key on this host
  ntfy.enable = false;

  services.second-brain = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    environment = {
      GEN_URL = "http://100.69.0.2:11434";
      GEN_MODEL = "qwen3:8b";
      GEN_TIMEOUT = "300";
      ASSIST_MIN_SIM = "0.4";
      EMBED_NUM_CTX = "8192";
    };
  };
}
