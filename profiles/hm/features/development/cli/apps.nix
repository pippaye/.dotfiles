{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.hmProfiles.dev;
in
{
  config = {
    home.packages =
      with pkgs;
      [
        lsd
        cloc
        bat
        tlrc
        delta
        fzf
        rclone
      ]
      ++ (lib.optionals (!cfg.lite) [
        yazi
        lazygit
        devenv
        deploy-rs
        lazydocker
      ]);
  };
}
