{
  programs.ssh.settings."lemon" = {
    hostname = "198.252.98.154";
    user = "ashenye";
    port = 2222;
    serverAliveInterval = 60;
    serverAliveCountMax = 3;
    compression = true;
    extraOptions = {
      tcpKeepAlive = "yes";
    };
  };
}
