{
  plugins.mini = {
    enable = true;

    modules = {
      files = { };
      icons = { };
      indentscope = {
        symbol = "│";
        options = {
          try_as_border = true;
        };
        draw = {
          delay = 0;
          animation.__raw = "require('mini.indentscope').gen_animation.none()";
        };
      };
      surround = { };
    };
  };

  keymaps = [
    {
      mode = [ "n" ];
      key = "<leader>e";
      action.__raw = "function() if not MiniFiles.close() then MiniFiles.open(vim.api.nvim_buf_get_name(0), true) end end";
      options = {
        desc = "打开/关闭 mini.files 文件浏览器";
      };
    }
  ];
}
