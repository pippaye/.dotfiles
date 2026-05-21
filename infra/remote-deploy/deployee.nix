{ isLinux, ... }:
{
  assertions = [
    {
      assertion = isLinux;
      message = "This configuration is only for Linux systems.";
    }
  ];
  users.users = {
    deployee = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2qazCiKDHusEM9pxJ2VlvE+sZa5JZUrAEvy6CvD5uh remote-deploy@infra"
      ];
      hashedPassword = "$y$j9T$t/Cvl6/8QfmSpf59G7sxt1$HO6ltOhL5Fs3HGyJ..FCRbtfWWCICoiCuUk9SmL.jsC";
    };
  };
  security.sudo.extraConfig = ''
    deployee ALL=(ALL) NOPASSWD: ALL
  '';
}
