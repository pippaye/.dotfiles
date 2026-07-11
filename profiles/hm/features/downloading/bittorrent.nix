{
  pkgs,
  isLinux,
  lib,
  ...
}:
{
  home.packages =
    with pkgs;
    lib.optionals isLinux [
      qbittorrent-enhanced
    ];
}
