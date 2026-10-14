{ ... }:
{
  osProfiles.common.bootloader = "grub";
  boot.loader.grub.devices = [ "/dev/sda" ];
  time.timeZone = "America/Los_Angeles";
}
