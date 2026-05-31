{
  pkgs,
  lib,
  config,
  isLinux,
  ...
}:
let
  cfg = config.hmProfiles.dev;
in
{
  home.packages = lib.mkIf (cfg.daily && isLinux) (
    with pkgs;
    [
      vscode
    ]
  );
}
