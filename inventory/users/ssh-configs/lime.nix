{
  programs.ssh.settings."lime" = {
    hostname = "210.121.44.78";
    user = "ashenye";
    port = 2222;
    serverAliveInterval = 60;
    serverAliveCountMax = 3;
    compression = true;
    TCPKeepAlive = "yes";
  };
}
