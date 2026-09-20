{ inputs, pkgs, ... }:
let
  site = inputs.wiki.packages.${pkgs.system}.default;
in
{
  home-manager.users.wiki =
    { pkgs, ... }:
    let
      # no user directive, so nginx never attempts setuid with all caps dropped
      conf = pkgs.writeText "nginx.conf" ''
        worker_processes 1;
        pid /tmp/nginx.pid;
        error_log /dev/stderr warn;

        events {
          worker_connections 128;
        }

        http {
          include /etc/nginx/mime.types;
          default_type application/octet-stream;
          charset utf-8;
          access_log off;
          server_tokens off;

          gzip on;
          gzip_vary on;
          gzip_types text/css application/javascript application/json application/xml image/svg+xml;

          client_body_temp_path /tmp/client_body;
          proxy_temp_path /tmp/proxy;
          fastcgi_temp_path /tmp/fastcgi;
          uwsgi_temp_path /tmp/uwsgi;
          scgi_temp_path /tmp/scgi;

          server {
            listen 8088;
            root /srv;
            index index.html;
            error_page 404 /404.html;

            # quartz emits page.html but links to /page
            location / {
              try_files $uri $uri.html $uri/ =404;
            }

            location /static/ {
              add_header Cache-Control "public, max-age=31536000, immutable";
            }
          }
        }
      '';
    in
    {
      home.stateVersion = "25.05";

      services.podman = {
        enable = true;

        containers.wiki = {
          image = "docker.io/library/nginx:1.31-alpine@sha256:62ff2089abf5a9ed33bd232895bef5e22f7bb4b200675cec49a5ebc48e3d4ac8";
          autoStart = true;
          ports = [ "127.0.0.1:8088:8088" ];
          exec = "-g \"daemon off;\"";
          volumes = [
            "${conf}:/etc/nginx/nginx.conf:ro"
            "${site}:/srv:ro"
          ];
          extraConfig = {
            Container = {
              # skips entrypoint, rewrites conf.d on a read-only rootfs
              Entrypoint = "nginx";
              User = "101:101";
              DropCapability = "ALL";
              NoNewPrivileges = true;
              ReadOnly = true;
              Tmpfs = "/tmp";
            };
            Service.Restart = "always";
          };
        };
      };
    };
}
