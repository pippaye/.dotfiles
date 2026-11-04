local group = vim.api.nvim_create_augroup("user_core", { clear = true })

-- 复制时短暂高亮选区
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank()
  end,
})

-- 录宏时临时显示命令行：cmdheight=0 时没有地方显示 "recording @q" 提示
vim.api.nvim_create_autocmd("RecordingEnter", {
  group = group,
  callback = function()
    vim.o.cmdheight = 1
  end,
})
vim.api.nvim_create_autocmd("RecordingLeave", {
  group = group,
  callback = function()
    vim.o.cmdheight = 0
  end,
})

-- 帮助页面不显示 mini.indentscope 竖线
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "help" },
  callback = function()
    vim.b.miniindentscope_disable = true
  end,
})

-- 重新打开文件时回到上次的光标位置（来自 NvChad）
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  callback = function()
    local line = vim.fn.line("'\"")
    if
      line > 1
      and line <= vim.fn.line("$")
      and vim.bo.filetype ~= "commit"
      and vim.fn.index({ "xxd", "gitrebase" }, vim.bo.filetype) == -1
    then
      vim.cmd('normal! g`"')
    end
  end,
})
