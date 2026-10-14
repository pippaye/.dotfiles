{ ... }:
{
  networking = {
    nameservers = [
      "8.8.8.8"
      "1.1.1.1"
    ];
    defaultGateway = {
      address = "38.246.237.126";
      interface = "ens18";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = true;
    interfaces.ens18.ipv4.addresses = [
      {
        address = "38.246.237.114";
        prefixLength = 25;
      }
    ];
  };
}
