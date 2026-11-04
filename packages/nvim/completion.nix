{
  # blink.cmp：补全 + snippet（读取 ./snippets 下的 VSCode 格式片段）
  # https://github.com/Saghen/blink.cmp

  plugins.blink-cmp = {
    enable = true;

    settings = {
      # 快捷键预设
      keymap = {
        preset = "default";

        # 自定义快捷键
        "<C-space>" = [
          "show"
          "show_documentation"
          "hide_documentation"
        ];
        "<C-e>" = [ "hide" ];
        "<C-y>" = [ "select_and_accept" ];

        "<C-k>" = [
          "select_prev"
          "fallback"
        ];
        "<C-j>" = [
          "select_next"
          "fallback"
        ];

        "<C-b>" = [
          "scroll_documentation_up"
          "fallback"
        ];
        "<C-f>" = [
          "scroll_documentation_down"
          "fallback"
        ];

        "<Tab>" = [
          "select_next"
          "snippet_forward"
          "fallback"
        ];
        "<S-Tab>" = [
          "select_prev"
          "snippet_backward"
          "fallback"
        ];
        "<CR>" = [
          "accept"
          "fallback"
        ];
      };

      # 补全来源
      sources = {
        default = [
          "lsp"
          "path"
          "snippets"
          "buffer"
        ];

        # 命令行补全
        cmdline = [ ];

        # 每个来源的配置
        providers = {
          lsp = {
            name = "LSP";
            module = "blink.cmp.sources.lsp";
            enabled = true;
            score_offset = 90;
          };

          path = {
            name = "Path";
            module = "blink.cmp.sources.path";
            enabled = true;
            score_offset = 3;
            opts = {
              trailing_slash = false;
              label_trailing_slash = true;
              get_cwd.__raw = "function(context) return vim.fn.expand(('#%d:p:h'):format(context.bufnr)) end";
              show_hidden_files_by_default = false;
            };
          };

          snippets = {
            name = "Snippets";
            module = "blink.cmp.sources.snippets";
            enabled = true;
            score_offset = 80;
            opts = {
              search_paths = [ "${./snippets}" ];
              global_snippets = [ "all" ];
              extended_filetypes = { };
              ignored_filetypes = [ ];
            };
          };

          buffer = {
            name = "Buffer";
            module = "blink.cmp.sources.buffer";
            enabled = true;
            score_offset = 5;
            opts = {
              min_keyword_length = 3;
              get_bufnrs.__raw = ''
                function()
                  return vim.api.nvim_list_bufs()
                end
              '';
            };
          };
        };
      };

      # 补全行为
      completion = {
        accept = {
          auto_brackets = {
            enabled = true;
          };
        };

        menu = {
          enabled = true;
          min_width = 15;
          max_height = 10;
          border = "rounded";
          winblend = 0;
          winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None";

          draw = {
            treesitter = [ "lsp" ];
            columns = [
              [ "kind_icon" ]
              [
                "label"
                "label_description"
              ]
              [ "kind" ]
            ];
          };
        };

        documentation = {
          auto_show = true;
          auto_show_delay_ms = 500;
          treesitter_highlighting = true;
          window = {
            min_width = 10;
            max_width = 60;
            max_height = 20;
            border = "rounded";
            winblend = 0;
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None";
          };
        };

        ghost_text = {
          enabled = false;
        };
      };

      # 签名帮助
      signature = {
        enabled = true;
        window = {
          border = "rounded";
          winblend = 0;
          winhighlight = "Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder";
        };
      };

      # 外观
      appearance = {
        use_nvim_cmp_as_default = true;
        nerd_font_variant = "mono";
        kind_icons = {
          Text = "󰊄";
          Method = "";
          Function = "󰡱";
          Constructor = "";
          Field = "";
          Variable = "󱀍";
          Class = "";
          Interface = "";
          Module = "󰕳";
          Property = "";
          Unit = "";
          Value = "";
          Enum = "";
          Keyword = "";
          Snippet = "";
          Color = "";
          File = "";
          Reference = "";
          Folder = "";
          EnumMember = "";
          Constant = "";
          Struct = "";
          Event = "";
          Operator = "";
          TypeParameter = "";
        };
      };
    };
  };
}
