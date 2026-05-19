{
  programs.ssh.settings."yuzu" = {
    hostname = "43.130.59.57";
    user = "ashenye";
    port = 2222;
    serverAliveInterval = 60;
    serverAliveCountMax = 3;
    compression = true;
    extraOptions = {
      TCPKeepAlive = "yes";
    };
  };
}
