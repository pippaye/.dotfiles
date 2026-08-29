{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # codex
    pi-coding-agent
  ];
}
