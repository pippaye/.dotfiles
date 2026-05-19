{
  programs.ssh.settings."zhuque" = {
    hostname = "zhuque.void";
    user = "root";
    port = 2222;
  };
  programs.ssh.settings."zhuque.zju" = {
    hostname = "zhuque.void";
    user = "root";
    port = 2222;
    proxyJump = "qingloong.zju";
  };
}
