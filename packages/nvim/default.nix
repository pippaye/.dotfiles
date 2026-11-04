# Neovim（nixvim）。lite / full 的全部差异都在这个文件里
{
  pkgs,
  lib,
  inputs,
  lite ? true,
}:
let
  nixvim = inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
nixvim.makeNixvimWithModule {
  inherit pkgs;
  module = {
    imports = [
      ./core.nix # 选项、快捷键、自动命令、诊断显示
      ./editor.nix # 主题、treesitter、telescope、mini.nvim
    ]
    ++ lib.optionals (!lite) [
      ./ui.nix # lualine、which-key、undotree、markdown-preview
      ./completion.nix # blink.cmp
      ./lsp.nix # LSP 通用设置 + conform
      ./langs.nix # 各语言的 LSP 与格式化工具
      ./dap.nix # 调试
      ./git.nix # gitsigns、lazygit
    ];

    plugins.treesitter.grammarPackages =
      with pkgs.vimPlugins.nvim-treesitter.builtGrammars;
      if lite then
        # lite：只保留配置文件类语言
        [
          bash
          comment
          diff
          git_config
          ini
          json
          lua
          markdown
          markdown_inline
          nix
          regex
          toml
          vim
          vimdoc
          xml
          yaml
        ]
      else
        pkgs.vimPlugins.nvim-treesitter.allGrammars;

    performance.byteCompileLua.enable = true;

    # Nixvim's manpage build currently requires a pandoc build with Lua support.
    enableMan = false;

    viAlias = true;
    vimAlias = true;
  };
}
