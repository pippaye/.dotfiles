-- 诊断显示（Neovim 0.11+ 原生能力）
--   signs：行号旁图标
--   virtual_lines：诊断以虚拟行显示在代码下方（替代 lsp_lines 插件）
local severity = vim.diagnostic.severity
vim.diagnostic.config({
  signs = {
    text = {
      [severity.ERROR] = " ",
      [severity.WARN] = " ",
      [severity.HINT] = "󰌵",
      [severity.INFO] = " ",
    },
  },
  float = { border = "rounded" },
  virtual_text = false,
  virtual_lines = true,
})
