{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.baseline;
in
{
  options.server.baseline.enable = lib.mkEnableOption "Baseline server configuration";

  config = lib.mkIf cfg.enable {
    svc.enable = lib.mkDefault true;
    server.dns.enable = lib.mkDefault true;

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    nixpkgs.config.allowUnfree = true;

    networking.useNetworkd = true;

    # tailnet names are unresolvable without magicdns
    networking.hosts."100.69.69.216" = [ "git.zorse-ruffe.ts.net" ];

    nix.gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 5d";
    };

    nix.optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };

    services.journald.extraConfig = ''
      SystemMaxUse=500M
    '';

    time.timeZone = "America/Chicago";

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
    };

    programs.zsh.enable = true;
    environment.pathsToLink = [ "/share/zsh" ];

    environment.systemPackages = with pkgs; [
      # tools/etc
      sops
      ssh-to-age
      wget
      git
      htop
      curl
      tree
      fastfetch
      starship
      whois
      parted
      usbutils
      smartmontools
      pciutils
      file
      dig
      oh-my-zsh
      autojump
      jq
      screen
      eza
      vim
      python3
      vnstat
    ];

    services = {
      tailscale.enable = true;
      qemuGuest.enable = true;
    };

    system.stateVersion = "25.05";
  };
}
