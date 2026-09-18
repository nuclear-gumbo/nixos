{
  home-manager.users.forgejo =
    { ... }:
    {
      home.stateVersion = "25.05";

      services.podman = {
        enable = true;

        networks.forgejo = { };

        containers.forgejo = {
          image = "codeberg.org/forgejo/forgejo:16-rootless@sha256:5effb7305584aca479b29fde6f9631a6dbe86ae798ae02eeea33a3666f0c0bf8";
          autoStart = true;
          network = "forgejo.network";
          userNS = "keep-id:uid=1000,gid=1000";
          ports = [
            "127.0.0.1:3000:3000"
            "127.0.0.1:2222:2222"
          ];
          volumes = [
            "/var/lib/forgejo/data:/var/lib/gitea:Z"
            "/var/lib/forgejo/config:/etc/gitea:Z"
          ];
          environment = {
            FORGEJO__server__DOMAIN = "git.zorse-ruffe.ts.net";
            FORGEJO__server__ROOT_URL = "https://git.zorse-ruffe.ts.net/";
            FORGEJO__server__PROTOCOL = "http";
            FORGEJO__server__HTTP_ADDR = "0.0.0.0";
            FORGEJO__server__HTTP_PORT = "3000";

            FORGEJO__server__START_SSH_SERVER = "true";
            FORGEJO__server__SSH_LISTEN_PORT = "2222";
            FORGEJO__server__SSH_PORT = "22";
            FORGEJO__server__SSH_DOMAIN = "git.zorse-ruffe.ts.net";

            FORGEJO__database__DB_TYPE = "postgres";
            FORGEJO__database__HOST = "forgejo-db:5432";
            FORGEJO__database__NAME = "forgejo";
            FORGEJO__database__USER = "forgejo";

            FORGEJO__service__DISABLE_REGISTRATION = "true";
            FORGEJO__service__REQUIRE_SIGNIN_VIEW = "false";
            FORGEJO__service__ENABLE_NOTIFY_MAIL = "false";
            FORGEJO__service__DEFAULT_KEEP_EMAIL_PRIVATE = "true";

            FORGEJO__security__INSTALL_LOCK = "true";
            FORGEJO__session__COOKIE_SECURE = "true";
            FORGEJO__session__PROVIDER = "db";

            FORGEJO__actions__ENABLED = "true";

            FORGEJO__repository__DEFAULT_PRIVATE = "private";
            FORGEJO__repository__DEFAULT_BRANCH = "main";

            FORGEJO__repository_0X2E_signing__FORMAT = "ssh";
            FORGEJO__repository_0X2E_signing__SIGNING_KEY = "/var/lib/gitea/ssh-signing-key.pub";
            FORGEJO__repository_0X2E_signing__SIGNING_NAME = "forgejo-instance";
            FORGEJO__repository_0X2E_signing__SIGNING_EMAIL = "noreply@gaialabs.space";
            FORGEJO__repository_0X2E_signing__MERGES = "always";
            # signs renovate's platformCommit API writes
            FORGEJO__repository_0X2E_signing__CRUD_ACTIONS = "pubkey";

            FORGEJO__log__LEVEL = "Info";
          };
          environmentFile = [ "/run/secrets/forgejo.env" ];
          extraConfig = {
            Container = {
              DropCapability = "ALL";
              NoNewPrivileges = true;
            };
            Service.Restart = "always";
            Unit = {
              After = [ "podman-forgejo-db.service" ];
              Wants = [ "podman-forgejo-db.service" ];
            };
          };
        };

        containers.forgejo-db = {
          image = "docker.io/library/postgres:18-alpine@sha256:6c538e7206ea40ff740ef27883529390a690b6ead6ba96b44c67a9f7c638e8fd";
          autoStart = true;
          network = "forgejo.network";
          networkAlias = [ "forgejo-db" ];
          volumes = [ "/var/lib/forgejo/db:/var/lib/postgresql/data:Z" ];
          environment = {
            POSTGRES_DB = "forgejo";
            POSTGRES_USER = "forgejo";
            PGDATA = "/var/lib/postgresql/data/pgdata";
          };
          environmentFile = [ "/run/secrets/forgejo-db.env" ];
          extraConfig = {
            Container = {
              DropCapability = "ALL";
              AddCapability = [
                "CHOWN"
                "DAC_READ_SEARCH"
                "FOWNER"
                "SETGID"
                "SETUID"
              ];
              NoNewPrivileges = false;
            };
            Service.Restart = "always";
          };
        };
      };
    };

  sops.secrets = {
    "forgejo.env" = {
      sopsFile = ../../../../secrets/srv-n3.forgejo.env;
      format = "binary";
      path = "/run/secrets/forgejo.env";
      owner = "forgejo";
      group = "forgejo";
      mode = "0400";
    };
    "forgejo-db.env" = {
      sopsFile = ../../../../secrets/srv-n3.forgejo-db.env;
      format = "binary";
      path = "/run/secrets/forgejo-db.env";
      owner = "forgejo";
      group = "forgejo";
      mode = "0400";
    };
  };
}
