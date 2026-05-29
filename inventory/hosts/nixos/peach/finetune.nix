{
  config,
  pkgs,
  lib,
  ...
}:

{
  system.stateVersion = "25.11";

  services.openssh.enable = true;

  users.users.root = {
    password = "root";
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    htop
  ];

  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
  services.openssh.settings.PasswordAuthentication = lib.mkForce true;
  services.openssh.ports = [ 22 ];
}
