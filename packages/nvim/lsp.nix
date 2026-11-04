{ lib, ... }:
{
  plugins.lsp = {
    enable = true;
    inlayHints = true;

    keymaps = {
      silent = true;
      # "<按键>" = [ "vim.lsp.buf 方法" "描述" ]
      lspBuf =
        lib.mapAttrs
          (_: v: {
            action = builtins.elemAt v 0;
            desc = builtins.elemAt v 1;
          })
          {
            gd = [
              "definition"
              "Goto Definition"
            ];
            gr = [
              "references"
              "Goto References"
            ];
            gD = [
              "declaration"
              "Goto Declaration"
            ];
            gI = [
              "implementation"
              "Goto Implementation"
            ];
            gT = [
              "type_definition"
              "Type Definition"
            ];
            K = [
              "hover"
              "Hover"
            ];
            "<leader>ca" = [
              "code_action"
              "Code Action"
            ];
            "<leader>cr" = [
              "rename"
              "Rename"
            ];
            "<leader>cw" = [
              "workspace_symbol"
              "Workspace Symbol"
            ];
          };
    };
  };

  # 保存时格式化。各语言的格式化工具在 langs.nix 里配置
  plugins.conform-nvim = {
    enable = true;
    settings = {
      notify_on_error = true;
      # 函数定义在 lua/format.lua
      format_on_save.__raw = "format_on_save";
      format_after_save.__raw = "format_after_save";
      # 配置了格式化工具的语言只用该工具；没配置的语言用 LSP 格式化
      default_format_opts.lsp_format = "fallback";
      formatters_by_ft."_" = {
        __unkeyed-1 = "trim_whitespace";
        lsp_format = "prefer";
      };
    };
  };

  # format.lua 定义的局部函数要被 conform 的 setup 引用，所以必须放在 Pre 且不能包 do ... end
  extraConfigLuaPre = builtins.readFile ./lua/format.lua;

  extraConfigLua = ''
    do
    ${builtins.readFile ./lua/lsp.lua}
    end
  '';
}
