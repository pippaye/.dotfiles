{
  config,
  lib,
  ...
}:
let
  cfg = config.hmProfiles.dev;
in
{
  programs.kitty = lib.mkIf cfg.daily {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    extraConfig = ''
      enable_audio_bell no
      hide_window_decorations yes
      tab_bar_edge top
      tab_bar_style powerline
      tab_powerline_style slanted
      shell_integration enabled
      notify_on_cmd_finish unfocused 5.0 notify
      remember_window_size  yes
      allow_hyperlinks yes
      hyperlink_modifier ctrl
      map ctrl+shift+enter new_window_with_cwd
      map f1 launch --stdin-source=@screen_scrollback nvim -R -
      map f2 launch --stdin-source=@last_cmd_output nvim -R -
      allow_remote_control yes
      listen_on unix:/tmp/kitty
    '';
  };
}
