{
  server.ban = {
    enable = true;

    addresses = [
      # cloudflare warp scraper pool. solved 0 anubis challenges over 23k requests
      "104.28.0.0/16"

      # random scraper solved over 1k anubis challenges in an hour
      "104.200.72.181"
    ];
  };
}
