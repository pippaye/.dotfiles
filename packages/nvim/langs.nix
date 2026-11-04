{ lib, pkgs, ... }:
{
  # ── LSP ─────────────────────────────────────────────────────────
  # package = null：不由 nixvim 提供，使用项目环境（flake / direnv）里的可执行文件
  plugins.lsp.servers = {
    nil_ls.enable = true;
    lua_ls.enable = true;
    just.enable = true;
    jsonls.enable = true;
    dockerls.enable = true;

    pyright = {
      enable = true;
      package = null;
    };
    clangd = {
      enable = true;
      package = null;
    };
    cmake = {
      enable = true;
      package = null;
    };
    phan = {
      enable = true;
      package = null;
    };

    yamlls = {
      enable = true;
      extraOptions.settings.yaml.schemas = {
        kubernetes = "'*.yaml";
        "http://json.schemastore.org/github-workflow" = ".github/workflows/*";
        "http://json.schemastore.org/github-action" = ".github/action.{yml,yaml}";
        "http://json.schemastore.org/kustomization" = "kustomization.{yml,yaml}";
        "http://json.schemastore.org/chart" = "Chart.{yml,yaml}";
        "https://json.schemastore.org/dependabot-v2" = ".github/dependabot.{yml,yaml}";
        "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" =
          "*docker-compose*.{yml,yaml}";
        "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" =
          "*flow*.{yml,yaml}";
      };
    };

    beancount = {
      enable = true;
      rootMarkers = [
        "main.beancount"
        "main.bean"
        ".git"
      ];
      extraOptions.init_options = {
        journal_file = "main.beancount";
        diagnostic_flags = [ "!" ];
        completion.fuzzy_match_accounts = true;
      };
    };
  };

  filetype.extension = {
    bean = "beancount";
    beancount = "beancount";
  };

  # Rust：rust-analyzer 由 rustaceanvim 管理，可执行文件只用项目环境里的。
  # nixvim 默认会自带一份并放在 PATH 最前面，覆盖掉项目 devshell 里与工具链匹配的版本。
  dependencies.rust-analyzer.enable = false;
  plugins.rustaceanvim = {
    enable = true;
    settings = {
      tools.enable_clippy = true;
      server.default_settings.rust-analyzer = {
        cargo.allFeatures = true;
        check.command = "clippy";
        files.excludeDirs = [
          "target"
          ".git"
          ".cargo"
          ".github"
          ".direnv"
        ];
      };
    };
  };

  plugins.clangd-extensions.enable = true;

  # ── 格式化（conform.nvim）────────────────────────────────────────
  # 未列出的语言：有 LSP 格式化就用 LSP，否则只去除行尾空白（见 lsp.nix）
  plugins.conform-nvim.settings = {
    formatters_by_ft = {
      nix = [ "nixfmt" ];
      lua = [ "stylua" ];
      python = [
        "ruff_fix"
        "ruff_format"
        "ruff_organize_imports"
      ];
      c = [ "clang-format" ];
      cpp = [ "clang-format" ];
    };
    formatters = {
      nixfmt.command = lib.getExe pkgs.nixfmt;
      stylua.command = lib.getExe pkgs.stylua;
    };
  };
}
