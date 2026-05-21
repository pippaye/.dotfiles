{
  pkgs,
  lib,
  isLinux,
  ...
}:
{
  environment.systemPackages =
    with pkgs;
    lib.optionals isLinux [
      firefox
      chromium
    ];
}
