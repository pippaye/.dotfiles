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
      ./ui.nix # lualine、which-key、undotree
      ./completion.nix # blink.cmp
      ./lsp.nix # LSP 通用设置 + conform
      ./langs.nix # 各语言的 LSP 与格式化工具
      ./dap.nix # 调试
      ./git.nix # gitsigns、lazygit
    ];

    # treesitter 语法（不用 allGrammars：300+ 种、约 260 MiB）
    # 未列出的语言会退回 Vim 自带的正则高亮；lua/vim/vimdoc/markdown 等 Neovim 本身已内置
    plugins.treesitter.grammarPackages =
      with pkgs.vimPlugins.nvim-treesitter.builtGrammars;
      # lite + full
      # Shell / 系统
      [
        bash
        zsh
        awk
        ssh_config
        kitty
        nginx
        kconfig
      ]
      # 配置 / 数据
      ++ [
        json
        json5
        jsonnet
        yaml
        toml
        ini
        csv
        kdl
        jq
        http
        proto
        graphql
        helm
        mermaid
        xml
      ]
      # 仅 full
      ++ lib.optionals (!lite) (
        # Git
        [
          git_config
          git_rebase
          gitattributes
          gitcommit
          gitignore
          diff
        ]
        # Nix / 构建
        ++ [
          nix
          just
          cmake
          meson
          ninja
          dockerfile
        ]
        # C 家族 / 底层
        ++ [
          c
          cpp
          objc
          cuda
          glsl
          hlsl
          llvm
          mlir
          objdump
        ]
        # Rust / Go
        ++ [
          rust
          go
          gomod
          gosum
          gotmpl
          gowork
        ]
        # Python / Lua / Vim
        ++ [
          python
          lua
          luadoc
          luap
          vim
          vimdoc
          regex
          comment
        ]
        # Web
        ++ [
          html
          css
          scss
          javascript
          jsdoc
          typescript
          tsx
          vue
          astro
          php
        ]
        # 其他
        ++ [
          markdown
          markdown_inline
          sql
          java
          javadoc
          haskell
          slint
          typespec
          beancount
        ]
      );

    performance.byteCompileLua.enable = true;

    # Nixvim's manpage build currently requires a pandoc build with Lua support.
    enableMan = false;

    viAlias = true;
    vimAlias = true;
  };
}
