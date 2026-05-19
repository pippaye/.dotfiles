{ pkgs, ... }:
{
  services.netdata.enable = true;
  services.netdata.package = pkgs.netdata.override {
    withCloudUi = true;
  };
  networking.firewall.allowedTCPPorts = [ 19999 ];
}
