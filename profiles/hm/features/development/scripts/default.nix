{ lib, ... }:
let
  # 自动扫描当前目录下的所有常规脚本文件（排除 default.nix、隐藏文件和子目录）
  scripts =
    builtins.readDir ./.
    |> lib.filterAttrs (
      name: type:
      type == "regular"
      && name != "default.nix"
      && !(lib.hasPrefix "." name)
    );
in
{
  home.file =
    scripts
    |> lib.mapAttrs' (
      name: _:
      lib.nameValuePair ".local/bin/${name}" {
        source = ./. + "/${name}";
        executable = true;
      }
    );
}
