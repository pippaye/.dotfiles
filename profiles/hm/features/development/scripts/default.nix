{ lib, ... }:
let
  scripts = {
    switch-to-airpods = ./switch-to-airpods.sh;
    cleanup-bakup-files = ./cleanup-bakup-files.sh;
    printsops = ./printsops.sh;
    readlink-deep = ./readlink-deep.sh;
    toggle-swayidle = ./toggle-swayidle.sh;
    toggle-waybar = ./toggle-waybar.sh;
    change-wallpaper = ./change-wallpaper.sh;
    check-libs = ./check-libs.sh;
    bark = ./bark.sh;
    tokenctl = ./tokenctl.sh;
    stash = ./stash.sh;
    import_codex = ./import_codex.sh;
    cheatsheet = ./cheatsheet.sh;
  };
in
{
  home.file =
    scripts
    |> (lib.mapAttrs' (
      name: path:
      lib.nameValuePair ".local/bin/${name}" {
        source = path;
        executable = true;
      }
    ));
}
