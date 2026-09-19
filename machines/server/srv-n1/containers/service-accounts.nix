{ lib, ... }:
let
  containerUsers = [
    "mealie"
    "newt"
    "karakeep"
    "kavita"
    "vaultwarden"
    "navidrome"
    "lubelogger"
    "adguard"
    "grafana"
    "immich"
    "immich-public"
    "uptime-kuma"
    "anubis"
    "caddy"
    "searxng"
    "obsidian"
  #  "owntracks"
  ];
in
{
  users.manageLingering = true;

  users.users = lib.genAttrs containerUsers (name: {
    isSystemUser = true;
    group = name;
    linger = true;
    home = "/var/lib/${name}";
    createHome = true;
    autoSubUidGidRange = true;
  });

  users.groups = lib.genAttrs containerUsers (_: { });
}
