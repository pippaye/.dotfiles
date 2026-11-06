{
  paths,
  me,
  ...
}:
let
  inherit (paths) infra;
in
{
  imports = [
    "${infra}/dnsctl"
  ];

  services.qemuGuest.enable = true;

  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=tty0"
  ];

  systemd.services."serial-getty@ttyS0" = {
    enable = true;
    wantedBy = [ "getty.target" ];
  };

  services.fail2ban.enable = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    priority = 100;
  };

  nix.optimise.automatic = false;

  security.acme = {
    acceptTerms = true;
    defaults.email = me.email;
  };

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "vm.swappiness" = 100;
    "vm.page-cluster" = 0;
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;

    virtualHosts."_" = {
      default = true;
      rejectSSL = true;
      extraConfig = ''
        return 444;
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
