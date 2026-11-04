-- 剪贴板
-- 本机：不设置 g:clipboard，由 Neovim 自动检测系统工具
--       （macOS 用 pbcopy/pbpaste；Linux 桌面用 PATH 里的 wl-copy/wl-paste，由桌面 profile 提供）。
-- SSH 下：复制走 OSC 52，由本机终端写入系统剪贴板；
--       粘贴只读 Neovim 自己的寄存器（终端读剪贴板在 kitty 默认会弹窗询问），
--       从本机粘贴进来请用终端的粘贴快捷键（Cmd+V / Ctrl+Shift+V）。
-- 注意：本文件会被内联进 init.lua 顶层，不能使用 return（会提前结束整个 init.lua）。
if vim.env.SSH_TTY ~= nil then
  local osc52 = require("vim.ui.clipboard.osc52")

  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end

  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end
