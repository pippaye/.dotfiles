{
  programs.ssh.settings."yuzu" = {
    hostname = "38.246.237.114";
    user = "ashenye";
    port = 2222;
    serverAliveInterval = 60;
    serverAliveCountMax = 3;
    compression = true;
    TCPKeepAlive = "yes";
  };
}
