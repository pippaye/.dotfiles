{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  gtk.gtk4.theme = config.gtk.theme;

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/sound" = {
        allow-volume-above-100-percent = true;
        event-sounds = false;
      };
      "org/gnome/desktop/interface/color-scheme" = {
        default = "prefer-dark";
      };
    };
  };
  home.packages = with pkgs; [
    dconf
  ];

  stylix = {
    enable = true;
    targets.neovim.enable = false;
    targets.nixvim.enable = false;
    targets.kitty.enable = true;
    targets.zen-browser.profileNames = [ "default-profile" ];
    targets.qt = {
      enable = true;
      platform = "qtct";
    };

    # Edited catppuccin
    base16Scheme = {
      base00 = "10101a"; # Default Background
      base01 = "16161f"; # Lighter Background (Used for status bars, line number and folding marks)
      base02 = "2b2b2b"; # Selection Background
      base03 = "45475a"; # Comments, Invisibles, Line Highlighting
      base04 = "585b70"; # Dark Foreground (Used for status bars)
      base05 = "fcfcfc"; # Default Foreground, Caret, Delimiters, Operators
      base06 = "f5e0dc"; # Light Foreground (Not often used)
      base07 = "b4befe"; # Light Background (Not often used)
      base08 = "f38ba8"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
      base09 = "fab387"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url
      base0A = "f9e2af"; # Classes, Markup Bold, Search Text Background
      base0B = "a6e3a1"; # Strings, Inherited Class, Markup Code, Diff Inserted
      base0C = "94e2d5"; # Support, Regular Expressions, Escape Characters, Markup Quotes
      base0D = "A594FD"; # Functions, Methods, Attribute IDs, Headings, Accent color
      base0E = "cba6f7"; # Keywords, Storage, Selector, Markup Italic, Diff Changed
      base0F = "f2cdcd"; # Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?>
    };

    cursor = {
      package = pkgs.apple-cursor;
      name = "Apple Cursor";
      size = 24;
    };

    fonts = with pkgs; {
      monospace = {
        package = nerd-fonts.fira-code;
        name = "FiraCode Nerd Font";
      };
      sansSerif = {
        package = lxgw-wenkai;
        name = "LXGW WenKai";
      };
      serif = {
        package = lxgw-wenkai-screen;
        name = "LXGW WenKai Screen";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 13;
        desktop = 13;
        popups = 13;
        terminal = 13;
      };
    };
    icons = {
      enable = true;
      package = pkgs.whitesur-icon-theme;
      dark = "WhiteSur-dark";
      light = "WhiteSur-light";
    };
    polarity = "dark";
  };
}
