-- 保存时自动格式化（conform.nvim）
-- 格式化超时的文件类型会被记下来，之后改为保存后异步格式化，避免卡住保存。
-- format_on_save / format_after_save 被 lsp.nix 中的 conform 配置引用。
local slow_format_filetypes = {}

local function format_on_save(bufnr)
  if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
    return
  end
  if slow_format_filetypes[vim.bo[bufnr].filetype] then
    return
  end

  local function on_format(err)
    if err and err:match("timeout$") then
      slow_format_filetypes[vim.bo[bufnr].filetype] = true
    end
  end

  return { timeout_ms = 200 }, on_format
end

local function format_after_save(bufnr)
  if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
    return
  end
  if not slow_format_filetypes[vim.bo[bufnr].filetype] then
    return
  end
  return {}
end

-- :FormatDisable / :FormatEnable / :FormatToggle，带 ! 时只作用于当前 buffer
vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, { desc = "Disable autoformat-on-save", bang = true })

vim.api.nvim_create_user_command("FormatEnable", function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, { desc = "Re-enable autoformat-on-save" })

vim.api.nvim_create_user_command("FormatToggle", function(args)
  if args.bang then
    vim.b.disable_autoformat = not vim.b.disable_autoformat
  else
    vim.g.disable_autoformat = not vim.g.disable_autoformat
  end
end, { desc = "Toggle autoformat-on-save", bang = true })
