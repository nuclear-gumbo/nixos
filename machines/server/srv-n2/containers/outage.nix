{
  home-manager.users.outage =
    { pkgs, ... }:
    let
      page =
        {
          host,
          status,
        }:
        pkgs.writeText "${host}-outage.html" ''
          <!DOCTYPE html>
          <html lang="en">
          <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <meta name="robots" content="noindex">
          <meta name="color-scheme" content="dark">
          <title>${host} is down</title>
          <style>
            html { background: #15171a; }
            body {
              margin: 0;
              min-height: 100vh;
              display: flex;
              align-items: center;
              justify-content: center;
              padding: 1.5rem;
              background: #15171a;
              color: #e4e6e8;
              font: 1rem/1.6 system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
              -webkit-font-smoothing: antialiased;
            }
            main { max-width: 32rem; }
            h1 {
              margin: 0 0 0.75rem;
              font-size: 1.375rem;
              font-weight: 600;
              letter-spacing: -0.01em;
            }
            p { margin: 0; color: #a8adb4; }
            a {
              color: #7fb3ff;
              text-decoration: underline;
              text-underline-offset: 0.15em;
            }
            a:hover { color: #a8ccff; }
          </style>
          </head>
          <body>
          <main>
            <h1>${host} is down.</h1>
            <p>Please see <a href="https://${status}">${status}</a>.</p>
          </main>
          </body>
          </html>
        '';

      libresearch = page {
        host = "libresearch.space";
        status = "status.libresearch.space";
      };

      pasted = page {
        host = "pasted.space";
        status = "status.pasted.space";
      };

      # no user directive, so nginx never attempts setuid with all caps dropped
      conf = pkgs.writeText "nginx.conf" ''
        worker_processes 1;
        pid /tmp/nginx.pid;
        error_log /dev/stderr warn;

        events {
          worker_connections 64;
        }

        http {
          include /etc/nginx/mime.types;
          default_type text/html;
          access_log off;
          server_tokens off;

          client_body_temp_path /tmp/client_body;
          proxy_temp_path /tmp/proxy;
          fastcgi_temp_path /tmp/fastcgi;
          uwsgi_temp_path /tmp/uwsgi;
          scgi_temp_path /tmp/scgi;

          server {
            listen 8087;
            root /srv;

            location = /libresearch.html { }
            location = /pasted.html { }
            location / { return 404; }
          }
        }
      '';
    in
    {
      home.stateVersion = "25.05";

      services.podman = {
        enable = true;

        containers.outage = {
          image = "docker.io/library/nginx:1.31-alpine@sha256:df221db836e1754089190208cee7eeda94f233197056426eda74a43ab1abeac2";
          autoStart = true;
          ports = [ "127.0.0.1:8087:8087" ];
          exec = "-g \"daemon off;\"";
          volumes = [
            "${conf}:/etc/nginx/nginx.conf:ro"
            "${libresearch}:/srv/libresearch.html:ro"
            "${pasted}:/srv/pasted.html:ro"
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
