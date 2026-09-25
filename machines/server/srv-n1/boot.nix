{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  environment.systemPackages = [ pkgs.sbctl ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = lib.mkForce false;
        configurationLimit = 8;
      };
    };
    initrd = {
      systemd = {
        enable = true;
        emergencyAccess = true;
      };
      luks.devices."cryptroot" = {
        keyFile = lib.mkForce null;
        crypttabExtraOpts = [ "tpm2-device=auto" ];
      };
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      autoGenerateKeys.enable = true;
      autoEnrollKeys.enable = true;
      configurationLimit = 4;
      measuredBoot = {
        enable = true;
        pcrs = [
          0
          4
          7
        ];
      };
    };
  };
}
