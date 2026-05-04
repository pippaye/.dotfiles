{
  config,
  pkgs,
  me,
  paths,
  ...
}:
{
  virtualisation.docker.enable = true;
  users.users.ashenye.extraGroups = [ "docker" ];
  services.qbittorrent = {
    enable = true;
    openFirewall = true;
    webuiPort = 38081;
    package = pkgs.qbittorrent-enhanced-nox;
  };
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  systemd.services.qbittorrent.serviceConfig.Slice =
    config.osProfiles.features.tproxy.tproxyBypass.sliceName;

  infra.dnsctl.nginxVirtualHosts = {
    jellyfin = {
      enableACME = false;
      useACMEHost = "zjucst.pippaye.top";
      locations."/" = {
        proxyPass = "http://localhost:38083";
      };
    };
    calibre = {
      enableACME = false;
      useACMEHost = "zjucst.pippaye.top";
      locations."/" = {
        proxyPass = "http://localhost:38084";
      };
    };
    sonarr = {
      enableACME = false;
      useACMEHost = "zjucst.pippaye.top";
      locations."/" = {
        proxyPass = "http://localhost:38085";
      };
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    clientMaxBodySize = "500m";

    virtualHosts."_" = {
      default = true;
      rejectSSL = true;
      extraConfig = ''
        return 444;
      '';
    };
  };

  users.users.nginx.extraGroups = [ "acme" ];

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  sops.secrets."CF_DNS_TOKEN" = {
    owner = "acme";
    mode = "0400";
    sopsFile = "${paths.secrets}/api-tokens.yaml";
  };

  sops.templates."acme-cloudflare.env" = {
    owner = "acme";
    mode = "0400";
    content = ''
      CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder.CF_DNS_TOKEN}
      CLOUDFLARE_ZONE_API_TOKEN=${config.sops.placeholder.CF_DNS_TOKEN}
    '';
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = me.email;
    certs."zjucst.pippaye.top" = {
      domain = "*.zjucst.pippaye.top";
      dnsProvider = "cloudflare";
      environmentFile = config.sops.templates."acme-cloudflare.env".path;
    };
  };

  # services.calibre-web = {
  #   enable = true;
  #   listen.port = 38084;
  #   options.enableBookUploading = true;
  # };

  services.sonarr = {
    enable = true;
    group = "qbittorrent";
    user = "qbittorrent";
    openFirewall = true;
    settings = {
      server.port = 38085;
    };
  };
}
