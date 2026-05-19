{ config, paths, ... }:
{
  sops.secrets = {
    JUMP_TO_ZZM = {
      mode = "0400";
      sopsFile = "${paths.secrets}/zju.yaml";
    };
    YU_SG_KEY = {
      mode = "0400";
      sopsFile = "${paths.secrets}/zju.yaml";
    };
  };

  sops.templates."zju-lab-serv-w3090.conf".content = ''
    Host jump-to-zhao.zju
      HostName 10.15.201.91
      User zzm
      Port 22234
      IdentityFile ${config.sops.secrets.JUMP_TO_ZZM.path}
    Host zhao.zju
      HostName 172.16.0.109
      User zhao
      ProxyJump jump-to-zhao.zju
  '';
  programs.ssh = {
    settings = {
      "zhang.zju" = {
        hostname = "10.98.36.162";
        user = "ubuntu";
        port = 22;
      };
      "yu-sg.zju" = {
        hostname = "143.198.205.199";
        user = "jiongchiyu";
        port = 6666;
        identityFile = config.sops.secrets.YU_SG_KEY.path;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        compression = true;
        TCPKeepAlive = "yes";
      };
    };
    includes = [
      config.sops.templates."zju-lab-serv-w3090.conf".path
    ];
  };
}
