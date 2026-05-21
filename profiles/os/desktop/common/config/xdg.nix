{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    xdg-utils
  ];
  xdg = {
    terminal-exec = {
      enable = true;
      package = pkgs.kitty;
      settings = {
        default = [
          "kitty.desktop"
        ];
      };
    };
    portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-gtk
      ];
      config = {
        common = {
          default = [
            # "gnome"
            "gtk"
          ];
        };
      };
    };
  };
}
