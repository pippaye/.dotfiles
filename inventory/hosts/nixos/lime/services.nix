{ ... }:
{
  virtualisation.docker.enable = true;
  users.users.ashenye.extraGroups = [ "docker" ];

  infra.dnsctl = {
    ipv4 = "210.121.44.78";
    domain = "pippaye.top";

    nginxVirtualHosts.cpa.locations."/" = {
      proxyPass = "http://127.0.0.1:38001";
    };
  };
}
