{
  paths,
  ...
}@input:
let
  inherit (paths) osProfiles;
  zjucst = import "${paths.infra}/network/zjucst.nix" input;
  lanIface = "lan0";
  rdmaIfaceP0 = "rdma0";
  rdmaIfaceP1 = "rdma1";
  wifiIface = "wifi0";
  mvlanIface = "lan0v0";
in
{
  imports = [
    "${osProfiles}/hardware/wireless.nix"
    (zjucst.nixosConfig.default {
      interface = mvlanIface;
      address = "192.168.231.2";
    })
  ];

  systemd.network.netdevs."20-${mvlanIface}" = {
    netdevConfig = {
      Name = mvlanIface;
      Kind = "macvlan";
    };
    macvlanConfig = {
      Mode = "bridge";
    };
  };

  systemd.network.networks."10-${lanIface}" = {
    matchConfig.Name = lanIface;
    networkConfig = {
      MACVLAN = mvlanIface;
    };
  };

  systemd.network.links."10-${lanIface}" = {
    matchConfig.MACAddress = "50:e9:71:03:9a:9c";
    linkConfig.Name = lanIface;
  };
  systemd.network.links."10-${wifiIface}" = {
    matchConfig.MACAddress = "5c:b4:7e:57:7b:eb";
    linkConfig.Name = wifiIface;
  };
  systemd.network.links."10-${rdmaIfaceP0}" = {
    matchConfig.MACAddress = "24:1c:04:f3:dc:cf";
    linkConfig.Name = rdmaIfaceP0;
  };
  systemd.network.links."10-${rdmaIfaceP1}" = {
    matchConfig.MACAddress = "24:1c:04:f3:dc:d0";
    linkConfig.Name = rdmaIfaceP1;
  };
  networking.interfaces."${wifiIface}".useDHCP = true;
  networking.interfaces."${lanIface}".useDHCP = false;
  networking.interfaces.${mvlanIface}.useDHCP = false;
  networking.interfaces."${rdmaIfaceP0}".useDHCP = false;
  networking.interfaces.${rdmaIfaceP1}.useDHCP = false;
  systemd.network.networks."40-${wifiIface}".dhcpV4Config.RouteMetric = 200;
}
