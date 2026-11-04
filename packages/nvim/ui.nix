let
  inherit (import ./helpers.nix) bind;
in
{
  plugins.which-key.enable = true;

  plugins.undotree = {
    enable = true;
    settings = {
      autoOpenDiff = true;
      focusOnToggle = true;
    };
  };

  plugins.markdown-preview = {
    enable = true;
    settings = {
      browser = "zen";
      echo_preview_url = 1;
      port = "6969";
      preview_options = {
        disable_filename = 1;
        disable_sync_scroll = 1;
        sync_scroll_type = "middle";
      };
      theme = "dark";
    };
  };

  keymaps = [
    (bind "n" "<leader>ut" "<cmd>UndotreeToggle<CR>" "Undotree")
    (bind "n" "<leader>mp" "<cmd>MarkdownPreview<cr>" "Toggle Markdown Preview")
  ];

  plugins.lualine = {
    enable = true;
    settings = {
      options = {
        globalstatus = true;
        theme = "catppuccin-nvim"; # 跟随 catppuccin 当前 flavour
      };
      sections = {
        lualine_a = [
          {
            __unkeyed-1 = "mode";
            icon = "";
          }
        ];
        lualine_b = [
          {
            __unkeyed-1 = "branch";
            icon = "";
          }
          {
            __unkeyed-1 = "diff";
            symbols = {
              added = " ";
              modified = " ";
              removed = " ";
            };
          }
        ];
        lualine_c = [
          {
            __unkeyed-1 = "diagnostics";
            sources = [ "nvim_lsp" ];
            symbols = {
              error = " ";
              warn = " ";
              info = " ";
              hint = "󰝶 ";
            };
          }
        ];
        lualine_x = [
          {
            __unkeyed-1 = "filetype";
            icon_only = true;
            separator = "";
            padding = {
              left = 1;
              right = 0;
            };
          }
          {
            __unkeyed-1 = "filename";
            path = 1;
          }
        ];
        lualine_y = [
          {
            __unkeyed-1 = "progress";
          }
        ];
        lualine_z = [
          {
            __unkeyed-1 = "location";
          }
        ];
      };
    };
  };
}
