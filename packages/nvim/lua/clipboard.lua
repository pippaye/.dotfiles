-- 剪贴板统一走 OSC 52：本机、SSH、zellij 里都由终端负责写入系统剪贴板，不依赖 wl-copy / pbcopy。
-- 复制：发 OSC 52 序列给终端。
-- 粘贴：只读 Neovim 自己的寄存器。终端读取剪贴板（OSC 52 read）在 kitty 默认会弹窗询问，
--      所以从外部程序粘贴进来请用终端的粘贴快捷键（Cmd+V / Ctrl+Shift+V）。
local osc52 = require("vim.ui.clipboard.osc52")

local function paste()
  return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
end

vim.g.clipboard = {
  name = "OSC 52",
  copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
  paste = { ["+"] = paste, ["*"] = paste },
}
