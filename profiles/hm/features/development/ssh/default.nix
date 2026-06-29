{ pkgs, ... }:
{
  home.packages = [
    pkgs.sshpass
  ];
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        setEnv = "TERM=xterm-256color";
      };
      "github.com" = {
        hostname = "ssh.github.com";
        port = 443;
      };
    };
  };
}
