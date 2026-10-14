{ ... }:
{
  virtualisation.docker.enable = true;
  users.users.ashenye.extraGroups = [ "docker" ];

  services.sing-box = {
    enable = true;
    settings = {
      log = {
        level = "info";
        timestamp = true;
      };

      inbounds = [
        {
          type = "vless";
          tag = "vless-reality";
          listen = "::";
          listen_port = 38443;

          users = [
            {
              name = "ashenye";
              uuid = {
                _secret = "/var/lib/sing-box/uuid";
              };
              flow = "xtls-rprx-vision";
            }
          ];

          tls = {
            enabled = true;
            server_name = "www.cloudflare.com";
            reality = {
              enabled = true;
              handshake = {
                server = "www.cloudflare.com";
                server_port = 443;
              };
              private_key = {
                _secret = "/var/lib/sing-box/reality-private-key";
              };
              short_id = [ "175635b801b89bc6" ];
            };
          };
        }
      ];

      outbounds = [
        {
          type = "direct";
          tag = "direct";
        }
      ];

      route.final = "direct";
    };
  };

  networking.firewall.allowedTCPPorts = [ 38443 ];

  infra.dnsctl = {
    ipv4 = "38.246.237.114";
    domain = "pippaye.top";
    nginxVirtualHosts = {
      "cpa.yuzu" = {
        dnsRecordExt.proxied = false;
        locations."/" = {
          proxyPass = "http://127.0.0.1:38001";
          extraConfig = ''
            proxy_buffering off;
            proxy_cache off;

            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
            proxy_connect_timeout 60s;

            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header X-Accel-Buffering "no";
            chunked_transfer_encoding on;
          '';
        };
      };
    };
  };
}
