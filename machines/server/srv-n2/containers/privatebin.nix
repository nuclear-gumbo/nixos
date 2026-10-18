{
  home-manager.users.privatebin =
    { pkgs, ... }:
    let
      confPhp = pkgs.writeText "conf.php" ''
        [main]
        name = "pasted.space"
        basepath = "https://pasted.space/"
        discussion = false
        opendiscussion = false
        password = true
        fileupload = false
        burnafterreadingselected = false
        defaultformatter = "plaintext"
        sizelimit = 10485760
        template = "bootstrap5"
        languageselection = false
        qrcode = false
        icon = none
        httpwarning = false
        compression = zlib
        info = "More information on the <a href='https://privatebin.info/'>project page</a>. Maintained with ❤️ at <a href='https://codeberg.org/sensei/nixos'>codeberg.org/sensei/nixos</a>."

        [expire]
        default = 1month

        [expire_options]
        1hour = 3600
        1day = 86400
        1week = 604800
        1month = 2592000
        never = 0

        [formatter_options]
        plaintext = "Plain Text"
        syntaxhighlighting = "Source Code"
        markdown = "Markdown"

        [traffic]
        limit = 10
        header = "X_FORWARDED_FOR"

        [purge]
        limit = 300
        batchsize = 10

        [model]
        class = Filesystem

        [model_options]
        dir = PATH "data"
      '';
    in
    {
      home.stateVersion = "25.05";

      services.podman = {
        enable = true;

        containers.privatebin = {
          image = "docker.io/privatebin/nginx-fpm-alpine:2.1.0@sha256:b221c93dea1610380c5a64ca0318d1447f5197f7a4fc790467eb14e25eb15ba7";
          autoStart = true;
          userNS = "keep-id:uid=65534,gid=82";
          ports = [ "127.0.0.1:8083:8080" ];
          volumes = [
            "/var/lib/privatebin/data:/srv/data"
            "${confPhp}:/srv/cfg/conf.php:ro"
          ];
          environment = {
            PHP_TZ = "UTC";
            CONFIG_PATH = "/srv/cfg";
          };
          extraConfig = {
            Container = {
              DropCapability = "ALL";
              NoNewPrivileges = true;
            };
            Service.Restart = "always";
          };
        };
      };
    };
}
