{
  programs.ssh.settings."lan" = {
    hostname = "lan.void";
    user = "ashenye";
    port = 2222;
  };
  programs.ssh.settings."lan.zju" = {
    hostname = "lan.void";
    user = "ashenye";
    port = 2222;
    proxyJump = "qingloong.zju";
  };
}
