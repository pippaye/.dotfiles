{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      nerd-fonts.fira-code
      jetbrains-mono
      noto-fonts
      noto-fonts-cjk-serif
      lxgw-wenkai
      lxgw-neoxihei
      lxgw-wenkai-screen
      source-han-sans
      roboto
      source-sans
      my-pkgs.fonts
    ];
    enableDefaultPackages = false;
    fontconfig = {
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [
          "FiraCode Nerd Font"
          "LXGW WenKai Mono"
          "Noto Sans Mono CJK SC"
        ];
        sansSerif = [
          "LXGW Neo XiHei"
          "Noto Sans CJK SC"
        ];
        serif = [
          "LXGW WenKai Screen"
          "Noto Serif CJK SC"
        ];
      };
    };
  };
}
