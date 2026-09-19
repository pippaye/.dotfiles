{
  pkgs,
  ...
}:
let
  preferences = with pkgs; {
    terminal = {
      pkg = kitty;
      desktopEntry = "kitty.desktop";
      binname = "kitty";
    };
    shell = {
      pkg = zsh;
      desktopEntry = "zsh.desktop";
      binname = "zsh";
    };
    editor = {
      pkg = neovim;
      desktopEntry = "nvim.desktop";
      binname = "nvim";
    };
    browser = {
      desktopEntry = "zen-beta.desktop";
      binname = "zen";
    };
    file-manager = {
      pkg = yazi;
      desktopEntry = "yazi.desktop";
      binname = "yazi";
    };
    img-viewer = {
      pkg = imv;
      desktopEntry = "imv.desktop";
      binname = "imv";
    };
    pdf-viewer = {
      pkg = zathura;
      desktopEntry = "org.pwmt.zathura.desktop";
      binname = "zathura";
    };
    video-player = {
      pkg = mpv;
      desktopEntry = "mpv.desktop";
      binname = "mpv";
    };
    # music-player = {
    #   pkg = mpd;
    #   desktopEntry = "mpd.desktop";
    # };
  };
in
{
  home.sessionVariables = {
    EDITOR = preferences.editor.binname;
    VISUAL = preferences.editor.binname;
    BROWSER = preferences.browser.binname;
    TERMINAL = preferences.terminal.binname;
    # SHELL = preferences.shell.binname;
    # TODO
    SHELL = "$HOME/.nix-profile/bin/zsh";
    # XDG Base Directory Specification
    XDG_BIN_HOME = "$HOME/.local/bin";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_STATE_HOME = "$HOME/.local/state";
  };
  xdg.mimeApps = rec {
    enable = true;
    associations.added = defaultApplications;
    defaultApplications = {
      "inode/directory" = preferences.file-manager.desktopEntry;
      "x-scheme-handler/http" = preferences.browser.desktopEntry;
      "x-scheme-handler/https" = preferences.browser.desktopEntry;
      "application/xhtml+xml" = preferences.browser.desktopEntry;
      "application/x-xopp" = [ "com.github.xournalpp.xournalpp.desktop" ];
      "text/html" = preferences.browser.desktopEntry;
      "text/plain" = preferences.editor.desktopEntry;
      "text/markdown" = preferences.editor.desktopEntry;
      "test/x-markdown" = preferences.editor.desktopEntry;
      "application/pdf" = preferences.pdf-viewer.desktopEntry;
      "image/jpeg" = preferences.img-viewer.desktopEntry;
      "image/bmp" = preferences.img-viewer.desktopEntry;
      "image/gif" = preferences.img-viewer.desktopEntry;
      "image/jpg" = preferences.img-viewer.desktopEntry;
      "image/pjpeg" = preferences.img-viewer.desktopEntry;
      "image/png" = preferences.img-viewer.desktopEntry;
      "image/tiff" = preferences.img-viewer.desktopEntry;
      "image/webp" = preferences.img-viewer.desktopEntry;
      "image/x-bmp" = preferences.img-viewer.desktopEntry;
      "image/x-gray" = preferences.img-viewer.desktopEntry;
      "image/x-icb" = preferences.img-viewer.desktopEntry;
      "image/x-ico" = preferences.img-viewer.desktopEntry;
      "image/x-png" = preferences.img-viewer.desktopEntry;
      "image/x-portable-anymap" = preferences.img-viewer.desktopEntry;
      "image/x-portable-bitmap" = preferences.img-viewer.desktopEntry;
      "image/x-portable-graymap" = preferences.img-viewer.desktopEntry;
      "image/x-portable-pixmap" = preferences.img-viewer.desktopEntry;
      "image/x-xbitmap" = preferences.img-viewer.desktopEntry;
      "image/x-xpixmap" = preferences.img-viewer.desktopEntry;
      "image/x-pcx" = preferences.img-viewer.desktopEntry;
      "image/svg+xml" = preferences.img-viewer.desktopEntry;
      "image/svg+xml-compressed" = preferences.img-viewer.desktopEntry;
      "image/vnd.wap.wbmp" = preferences.img-viewer.desktopEntry;
      "image/x-icns" = preferences.img-viewer.desktopEntry;
      "x-scheme-handler/mailto" = preferences.browser.desktopEntry;
    };
  };
}
