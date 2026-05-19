{
  programs.ssh.settings."mume" = {
    hostname = "mume.void";
    user = "ashenye";
    port = 2222;
  };
  programs.ssh.settings."mume.zju" = {
    hostname = "mume.void";
    user = "ashenye";
    port = 2222;
    proxyJump = "qingloong.zju";
  };
}
