{ pkgs, isLinux, ... }:
{
  home.packages =
    with pkgs;
    [
    ]
    ++ (lib.optionals isLinux [
      typora
      obsidian
      pdfannots2json # for zotero interation plugin pdf utility
      xournalpp
      zotero
    ]);
}
