{ pkgs, ... }:
{
  users.users.ashenye = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [
      "wheel"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKl8IkGvU1g8lv/r+RtRVXXmtlW0XNac5zQrRgZ3RCij ashenye@lap01-macm4-mume"
    ];
  };

  security.sudo.extraRules = [
    {
      users = [ "ashenye" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
