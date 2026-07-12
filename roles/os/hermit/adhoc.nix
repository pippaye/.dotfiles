{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true; # Fetch the newest stable branch of Homebrew's git repo
      upgrade = true; # Upgrade outdated casks, formulae, and App Store apps
      # 'zap': uninstalls all formulae(and related files) not listed in the generated Brewfile
      cleanup = "zap";
    };

    taps = [
      {
        name = "AnInsomniacy/motrix-next";
        trusted = true;
      }
      {
        name = "chen08209/tap";
        trusted = true;
      }
    ];

    # Applications to install from Mac App Store using mas.
    # You need to install all these Apps manually first so that your apple account have records for them.
    # otherwise Apple Store will refuse to install them.
    # For details, see https://github.com/mas-cli/mas
    masApps = {
      # TODO Feel free to add your favorite apps here.

      # Wechat = 836500024;
      # QQ = 451108668;
    };

    # taps = [];

    # `brew install`
    # TODO Feel free to add your favorite apps here.
    brews = [
      "mas"
    ];

    # `brew install --cask`
    # TODO Feel free to add your favorite apps here.
    casks = [
      "firefox"
      "google-chrome"
      "visual-studio-code"

      "motrix-next"
      "c0re100-qbittorrent"

      # IM & audio & remote desktop & meeting
      "telegram"
      "discord"

      "stats" # beautiful system monitor
      "wireshark-app" # network analyzer

      "obsidian"
      "typora"
      "xournal++"
      "zotero"
      "gimp"
      "codex"
      "claude-code"
      {
        name = "motrix-next";

        # 安装或升级后移除隔离属性
        postinstall = "/usr/bin/xattr -cr '/Applications/MotrixNext.app'";
      }
      {
        name = "flclash";
      }
    ];
  };
}
