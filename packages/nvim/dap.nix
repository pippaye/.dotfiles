{ pkgs, ... }:
let
  inherit (import ./helpers.nix) bindLua;
  # 调用 require('dap').<fn>()，按下时才 require
  dap =
    key: fn: desc:
    bindLua "n" key "function() require('dap').${fn}() end" desc;
in
{
  plugins.dap = {
    enable = true;
    signs = {
      dapBreakpoint = {
        text = "";
        texthl = "DapBreakpoint";
      };
      dapBreakpointCondition = {
        text = "";
        texthl = "DapBreakpointCondition";
      };
      dapLogPoint = {
        text = "";
        texthl = "DapLogPoint";
      };
    };
  };
  plugins.dap-ui = {
    enable = true;
    settings.floating.mappings.close = [
      "<ESC>"
      "q"
    ];
  };
  plugins.dap-virtual-text.enable = true;

  # telescope-dap：<leader>df 选择调试配置
  extraPlugins = [ pkgs.vimPlugins.telescope-dap-nvim ];

  # 开始调试时自动打开 DAP UI，结束时自动关闭
  extraConfigLua = ''
    do
      local dap, dapui = require("dap"), require("dapui")
      dap.listeners.after.event_initialized["dapui_config"] = dapui.open
      dap.listeners.before.event_terminated["dapui_config"] = dapui.close
      dap.listeners.before.event_exited["dapui_config"] = dapui.close
    end
  '';

  keymaps = [
    (dap "<leader>db" "toggle_breakpoint" "Toggle Breakpoint")
    (bindLua "n" "<leader>dB"
      "function() require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: ')) end"
      "Breakpoint Condition"
    )
    (dap "<leader>dc" "continue" "Continue")
    # 运行前输入命令行参数（覆盖调试配置里的 args）
    (bindLua "n" "<leader>da" ''
      function()
        require("dap").continue({
          before = function(config)
            local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
            local args_str = type(args) == "table" and table.concat(args, " ") or args
            config = vim.deepcopy(config)
            config.args = function()
              local input = vim.fn.expand(vim.fn.input("Run with args: ", args_str))
              return require("dap.utils").splitstr(input)
            end
            return config
          end,
        })
      end
    '' "Run with Args")
    (dap "<leader>dC" "run_to_cursor" "Run to cursor")
    (dap "<leader>dg" "goto_" "Go to line (no execute)")
    (dap "<leader>di" "step_into" "Step into")
    (dap "<leader>do" "step_out" "Step Out")
    (dap "<leader>dO" "step_over" "Step Over")
    (dap "<leader>dj" "down" "Down")
    (dap "<leader>dk" "up" "Up")
    (dap "<leader>dl" "run_last" "Run Last")
    (dap "<leader>dp" "pause" "Pause")
    (bindLua "n" "<leader>dr" "function() require('dap').repl.toggle() end" "Toggle REPL")
    (dap "<leader>ds" "session" "Session")
    (dap "<leader>dt" "terminate" "Terminate")
    (bindLua "n" "<leader>du" "function() require('dapui').toggle() end" "Dap UI")
    (bindLua "n" "<leader>dw" "function() require('dap.ui.widgets').hover() end" "Widgets")
    (bindLua [ "n" "v" ] "<leader>de" "function() require('dapui').eval() end" "Eval")
    # .vscode/launch.json 由 nvim-dap 自动读取，无需 load_launchjs
    (bindLua "n" "<leader>df" "function() require('telescope').extensions.dap.configurations() end"
      "Debug Configurations"
    )
  ];
}
