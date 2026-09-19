{ ... }:
{
  osProfiles.common.bootloader = "grub";
  boot.loader.grub.devices = [ "/dev/sda" ];
  time.timeZone = "Asia/Seoul";
}
