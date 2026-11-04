-- 悬浮文档和函数签名浮窗使用圆角边框
-- （Neovim 0.11+ 中 vim.lsp.with() 已弃用，改为包装 vim.lsp.buf.*）
for _, name in ipairs({ "hover", "signature_help" }) do
  local orig = vim.lsp.buf[name]
  vim.lsp.buf[name] = function(opts)
    return orig(vim.tbl_extend("force", { border = "rounded" }, opts or {}))
  end
end

-- 光标停留时高亮当前符号的所有引用，移动光标时清除（替代 vim-illuminate）
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not (client and client:supports_method("textDocument/documentHighlight")) then
      return
    end
    local group = vim.api.nvim_create_augroup("user_lsp_highlight", { clear = false })
    vim.api.nvim_clear_autocmds({ buffer = args.buf, group = group })
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      buffer = args.buf,
      group = group,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      buffer = args.buf,
      group = group,
      callback = vim.lsp.buf.clear_references,
    })
  end,
})
