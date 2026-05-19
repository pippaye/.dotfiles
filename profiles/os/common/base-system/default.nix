{ lib, pkgs, ... }:
{
  imports = [
    ./i18n.nix
    ./sysctl.nix
    ./bootloader.nix
  ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
