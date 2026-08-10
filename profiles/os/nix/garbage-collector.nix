{ isLinux, isDarwin, ... }:
{
  nix.gc =
    if isLinux then
      {
        automatic = true;
        persistent = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
        randomizedDelaySec = "1h";
      }
    else if isDarwin then
      {
        automatic = true;
        options = "--delete-older-than 7d";
      }
    else
      throw "garbage-collector.nix: Unsupported platform";
}
