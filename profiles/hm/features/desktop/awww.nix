{ pkgs, paths, ... }:
let
  changeWallpaper = "${paths.hmProfiles}/features/development/scripts/change-wallpaper.sh";
in
{
  home.packages = with pkgs; [
    awww
  ];
  services.awww.enable = true;
  xdg.configFile."wallpapers" = {
    source = "${pkgs.my-pkgs.wallpapers}";
  };
  systemd.user.services.change-wallpaper = {
    Unit = {
      Description = "Change wallpaper every half hour";
    };
    Service = {
      Type = "oneshot";
      Environment = "PATH=${pkgs.awww}/bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin";
      ExecStart = changeWallpaper;
    };
  };
  systemd.user.timers.change-wallpaper = {
    Unit = {
      Description = "Timer to change wallpaper every half hour";
    };
    Timer = {
      OnCalendar = "*:0/30";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
