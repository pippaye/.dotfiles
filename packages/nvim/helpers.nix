# 快捷键简写：一个映射一行，代替 nixvim 每个映射 8 行的写法
#   bind     mode key action desc         # action 为按键/命令字符串
#   bindLua  mode key luaCode desc        # luaCode 为 Lua 表达式（通常是函数）
#   bindWith { expr = true; } mode key action desc
let
  bindWith = extra: mode: key: action: desc: {
    inherit mode key action;
    options = {
      inherit desc;
    }
    // extra;
  };
in
{
  inherit bindWith;
  bind = bindWith { };
  bindLua =
    mode: key: code: desc:
    bindWith { } mode key { __raw = code; } desc;
}
