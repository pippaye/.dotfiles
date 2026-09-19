{ ... }:
{
  networking = {
    nameservers = [
      "8.8.8.8"
      "1.1.1.1"
    ];
    defaultGateway = {
      address = "210.121.44.1";
      interface = "ens18";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = true;
    interfaces.ens18.ipv4.addresses = [
      {
        address = "210.121.44.78";
        prefixLength = 24;
      }
    ];
  };
}
