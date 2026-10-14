{ ... }:
{
  virtualisation.docker.enable = true;
  users.users.ashenye.extraGroups = [ "docker" ];

  # Secret files are created directly on lime and must be readable by sing-box:
  # /var/lib/sing-box/uuid and /var/lib/sing-box/reality-private-key.
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
    ipv4 = "210.121.44.78";
    domain = "pippaye.top";
    nginxVirtualHosts = {
      bark.locations."/".proxyPass = "http://127.0.0.1:33080";
      miniflux.locations."/".proxyPass = "http://127.0.0.1:38083";
      "cpa.lime" = {
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
      dav = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:36065";
          extraConfig = ''
            client_max_body_size 0;
            proxy_buffering off;
            proxy_request_buffering off;

            # Ensure COPY and MOVE commands work by rewriting the Destination header to
            # contain only the path, e.g. /test.txt. Note that the captured group already
            # includes the leading slash: adding another one would produce a Destination
            # such as //test.txt, which is parsed as a host name and rejected.
            set $dest $http_destination;
            if ($http_destination ~ "^https?://[^/]+(?<path>/.*)$") {
              set $dest $path;
            }
            proxy_set_header Destination $dest;
          '';
        };
      };
    };
  };
}
