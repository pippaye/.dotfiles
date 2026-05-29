_: {
  "ashenye@lan" = {
    role = "cat";
    tags = [ "daily" ];
    sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOvnf1TDq7kpCwOMFK0Vn6x7zjMEiGGIVhknGN+kC3n0 ashenye@desk00-u265kf-lan";
    hmConfig = ./home-manager/lan.nix;
    sshConfig = ./ssh-configs/lan.nix;
  };
  "ashenye@mume" = {
    role = "hermit";
    tags = [ "daily" ];
    sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKl8IkGvU1g8lv/r+RtRVXXmtlW0XNac5zQrRgZ3RCij ashenye@lap01-macm4-mume";
    hmConfig = ./home-manager/mume.nix;
  };
  "ashenye@bambu" = {
    role = "dog";
    tags = [
      "router"
      "cst"
    ];
    sshConfig = ./ssh-configs/bambu.nix;
    hmConfig = ./home-manager/bambu.nix;
  };
  "ashenye@citrus" = {
    role = "dog";
    tags = [ "vps" ];
    sshConfig = ./ssh-configs/citrus.nix;
  };
  "ashenye@lemon" = {
    role = "dog";
    tags = [ "vps" ];
    sshConfig = ./ssh-configs/lemon.nix;
  };
  "ashenye@yuzu" = {
    role = "dog";
    tags = [ "vps" ];
    sshConfig = ./ssh-configs/yuzu.nix;
  };
  "ashenye@peach" = {
    role = "dog";
    tags = [ "daily" ];
    sshPubKey = "";
    hmConfig = ./home-manager/peach.nix;
    sshConfig = ./ssh-configs/peach.nix;
  };
}
