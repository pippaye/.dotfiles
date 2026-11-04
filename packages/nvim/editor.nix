{ lib, ... }:
let
  inherit (import ./helpers.nix) bind bindLua;

  # 大文件（> 1 MiB）不启用 treesitter：解析耗时和内存随文件线性增长
  # （实测 29 MiB JSON：解析 2.4 s、内存 59 → 725 MiB），退回 Vim 自带的正则高亮
  isBigFile = ''
    function(_, buf)
      local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
      return stat ~= nil and stat.size > 1024 * 1024
    end
  '';
in
{
  colorschemes.catppuccin = {
    enable = true;
    settings = {
      flavour = "frappe";
      transparent_background = false;
      integrations = {
        blink_cmp = true;
        gitsigns = true;
        mini.enabled = true;
        native_lsp.enabled = true;
        telescope.enabled = true;
        treesitter = true;
        dap = true;
        dap_ui = true;
      };
    };
  };

  # 语法包在 default.nix 里按 lite/full 选择
  plugins.treesitter = {
    enable = true;
    # nvim-treesitter main 分支：高亮/缩进由 nixvim 在 FileType 时启动（settings.* 只给旧 master 分支用）
    highlight = {
      enable = true;
      disable.__raw = isBigFile;
    };
    indent = {
      enable = true;
      disable.__raw = isBigFile;
    };
  };

  plugins.mini = {
    enable = true;
    modules = {
      files = { }; # 文件浏览器（<leader>e）
      icons = { };
      pairs = { }; # 自动补全括号/引号
      surround = { };
      indentscope = {
        symbol = "│";
        options.try_as_border = true;
        draw = {
          delay = 0;
          animation.__raw = "require('mini.indentscope').gen_animation.none()";
        };
      };
    };
  };

  plugins.telescope = {
    enable = true;
    extensions.fzf-native.enable = true;
    settings = {
      defaults = {
        layout_config.horizontal.prompt_position = "top";
        sorting_strategy = "ascending";
      };
      pickers.colorscheme.enable_preview = true;
    };

    # "<按键>" = [ "picker" "描述" ]
    keymaps =
      lib.mapAttrs
        (_: v: {
          action = builtins.elemAt v 0;
          options.desc = builtins.elemAt v 1;
        })
        {
          "<leader><space>" = [
            "find_files"
            "Find project files"
          ];
          "<leader>/" = [
            "live_grep"
            "Grep (root dir)"
          ];
          "<leader>:" = [
            "command_history"
            "Command History"
          ];
          "<leader>b" = [
            "buffers"
            "Buffers"
          ];
          "<C-p>" = [
            "git_files"
            "Search git files"
          ];

          "<leader>ff" = [
            "find_files"
            "Find project files"
          ];
          "<leader>fr" = [
            "live_grep"
            "Find text"
          ];
          "<leader>fR" = [
            "resume"
            "Resume"
          ];
          "<leader>fg" = [
            "oldfiles"
            "Recent"
          ];
          "<leader>fb" = [
            "buffers"
            "Buffers"
          ];

          "<leader>gc" = [
            "git_commits"
            "Commits"
          ];
          "<leader>gs" = [
            "git_status"
            "Status"
          ];

          "<leader>sa" = [
            "autocommands"
            "Auto Commands"
          ];
          "<leader>sb" = [
            "current_buffer_fuzzy_find"
            "Buffer"
          ];
          "<leader>sc" = [
            "command_history"
            "Command History"
          ];
          "<leader>sC" = [
            "commands"
            "Commands"
          ];
          "<leader>sD" = [
            "diagnostics"
            "Workspace diagnostics"
          ];
          "<leader>sh" = [
            "help_tags"
            "Help pages"
          ];
          "<leader>sH" = [
            "highlights"
            "Search Highlight Groups"
          ];
          "<leader>sk" = [
            "keymaps"
            "Keymaps"
          ];
          "<leader>sM" = [
            "man_pages"
            "Man pages"
          ];
          "<leader>sm" = [
            "marks"
            "Jump to Mark"
          ];
          "<leader>so" = [
            "vim_options"
            "Options"
          ];
          "<leader>sR" = [
            "resume"
            "Resume"
          ];
          "<leader>uC" = [
            "colorscheme"
            "Colorscheme preview"
          ];
        };
  };

  keymaps = [
    (bind "n" "<leader>sd" "<cmd>Telescope diagnostics bufnr=0<cr>" "Document diagnostics")
    (bindLua "n" "<leader>e"
      "function() if not MiniFiles.close() then MiniFiles.open(vim.api.nvim_buf_get_name(0), true) end end"
      "打开/关闭 mini.files 文件浏览器"
    )
  ];
}
