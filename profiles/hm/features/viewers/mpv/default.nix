{
  pkgs,
  lib,
  isLinux,
  ...
}:
{
  programs.mpv = {
    # FIXIT
    enable = isLinux;
    package = pkgs.mpv.override {
      mpv-unwrapped = pkgs.mpv-unwrapped.override {
        vapoursynthSupport = true;
        vapoursynth = (pkgs.vapoursynth.withPlugins [ pkgs.vapoursynth-mvtools ]);
      };
      scripts =
        with pkgs.mpvScripts;
        [
          thumbfast
          mpv-notify-send
          uosc
        ]
        ++ (lib.optionals isLinux [
          mpris
        ]);
    };
  };
  home.packages = with pkgs; [
    yt-dlp
  ];
  xdg.configFile = {
    "mpv/mpv.conf".source = ./mpv.conf;
    "mpv/vs" = {
      source = ./vs;
      recursive = true;
    };
    "mpv/profiles.conf".source = ./profiles.conf;
    "mpv/scripts" = {
      source = ./scripts;
      recursive = true;
    };
    "mpv/script-opts" = {
      source = ./script-opts;
      recursive = true;
    };
    "mpv/input.conf".source = ./input.conf;
    "mpv/shaders/retro-crt.conf".text = import ./shaders/retro-crt.nix {
      inherit (pkgs.my-pkgs) retro-crt;
    };
    "mpv/shaders/anime4k.conf".text = import ./shaders/anime4k.nix {
      inherit (pkgs) anime4k;
    };
  };
}
