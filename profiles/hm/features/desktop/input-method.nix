{
  lib,
  pkgs,
  ...
}:
{

  # fix svg theme not showing

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;

    fcitx5.addons = with pkgs; [
      qt6Packages.fcitx5-chinese-addons
      fcitx5-fluent
      fcitx5-mellow-themes
      (fcitx5-rime.override {
        rimeDataPkgs = [
          nur.repos.nuclear06.rime-ice
          (pkgs.symlinkJoin {
            name = "empty-default-yaml";
            paths = [ pkgs.emptyDirectory ];
            postBuild = ''
              mkdir -p $out/share/rime-data
              touch $out/share/rime-data/default.yaml
            '';
          })
        ];
      })
    ];

    fcitx5.settings = {
      inputMethod = {
        "GroupOrder" = {
          "0" = "default";
        };
        "Groups/0" = {
          "Name" = "default";
          "DefaultIM" = "rime";
          "Default Layout" = "us";
        };
        "Groups/0/Items/0".Name = "rime";
      };
      globalOptions = {
        "Hotkey/EnumerateForwardKeys" = {
          "0" = "Shift+Shift_L";
        };
      };
      addons = {
        classicui.globalSection = {
          Theme = lib.mkForce "kwinblur-mellow-sakura-dark"; # FluentDark-solid/mellow-youlan-dark
          DarkTheme = lib.mkForce "kwinblur-mellow-sakura-dark"; # FluentDark-solid/mellow-youlan-dark
          # UseDarkTheme = true; # 跟随系统浅色/深色设置
        };
        clipboard = {
          globalSection = {
            "TriggerKey" = "";
          };
          # sections.TriggerKey = {
          #   "0" = "Control+Alt+semicolon";
          # };
        };
        notifications = {
          globalSection = { };
          sections.HiddenNotifications = {
            "0" = "fcitx-rime-deploy";
          };
        };
      };
    };
  };
  home.sessionVariables = {
    XMODIFIERS = "@im=fcitx";
    QT_IM_MODULE = "wayland";
    #GTK_IM_MODULE="fcitx";
  };
}
