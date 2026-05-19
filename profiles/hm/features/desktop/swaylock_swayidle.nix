{
  config,
  pkgs,
  lib,
  ...
}:
let
  command = "${pkgs.swaylock}/bin/swaylock && ${pkgs.niri}/bin/niri msg action power-off-monitors";
in
{
  services.swayidle = {
    enable = true;
    package = pkgs.swayidle;
    timeouts = [
      {
        timeout = 300;
        command = "${lib.getExe pkgs.swaylock} -fF";
      }
      # {
      #   timeout = 360;
      #   command = "${pkgs.systemd}/bin/systemctl suspend";
      # }
    ];

    events."before-sleep" = "${lib.getExe config.programs.swaylock.package} -fF";
    # events = [
    #   {
    #     event = "before-sleep";
    #     command = "${lib.getExe config.programs.swaylock.package} -fF";
    #   }
    # ];
  };
  programs.swaylock.enable = true;
  programs.swaylock.package = pkgs.swaylock-effects;
  programs.swaylock.settings = {
    show-failed-attempts = true;
    daemonize = true;
    screenshots = true;
    clock = true;
    indicator = true;
    indicator-radius = 120;
    indicator-thickness = 10;
    effect-blur = "7x5";
    effect-vignette = "0.5:0.5";
  };
}
