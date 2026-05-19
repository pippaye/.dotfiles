{
  config,
  pkgs,
  inputs,
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
  programs.swaylock.settings = {
    font = "FiraCode Nerd Font";
    font-size = 50;
    indicator-radius = 100;
    indicator-thickness = 10;
    # inside-color = "ffffff00";
    # key-hl-color = "5e81ac";
    # ring-color = "2e3440";
    line-uses-ring = true;
    # separator-color = "e5e9f022";
    # text-color = "d8dee9ff";
    # layout-text-color = "d8dee9ff";
    # text-clear-color = "d8dee9ff";
    # text-caps-lock-color = "d8dee9ff";
    indicator-idle-visible = true;
    daemonize = true;
    image = "${pkgs.my-pkgs.swaylock-background}/swaylock.jpg";
    scaling = "fill";
  };
}
