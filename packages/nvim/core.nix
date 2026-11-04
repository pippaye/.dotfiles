{ pkgs, ... }:
let
  inherit (import ./helpers.nix) bind bindLua bindWith;
  remap = bindWith { remap = true; };
  expr = bindWith { expr = true; };

  # 跳到下/上一个诊断并弹出浮窗；severity 为 null 时不限级别
  diag =
    key: count: severity: desc:
    let
      sev = if severity == null then "" else ", severity = vim.diagnostic.severity.${severity}";
    in
    bindLua "n" key
      "function() vim.diagnostic.jump({ count = ${toString count}, float = true${sev} }) end"
      desc;
in
{
  globals.mapleader = " ";

  # 剪贴板见 lua/clipboard.lua（本机用系统工具，SSH 下用 OSC 52）
  # 放在 Pre 里：必须在第一次使用剪贴板之前设置 g:clipboard
  extraConfigLuaPre = ''
    do
    ${builtins.readFile ./lua/clipboard.lua}
    end
  '';

  opts = {
    number = true;
    relativenumber = true;
    clipboard = "unnamedplus";
    mouse = "a";

    # 缩进
    tabstop = 2;
    softtabstop = 2;
    shiftwidth = 2;
    expandtab = true;
    smartindent = true;
    breakindent = true;

    # 显示
    cursorline = true;
    scrolloff = 8;
    linebreak = true;
    termguicolors = true;
    showmode = false;
    cmdheight = 0;
    fillchars.eob = " ";

    # 折叠默认关闭
    foldmethod = "manual";
    foldenable = false;

    # 分屏
    splitbelow = true;
    splitright = true;
    splitkeep = "screen";

    spell = false;
    swapfile = false;
    timeoutlen = 300;
  };

  # 每个 Lua 文件包在 do ... end 里，避免局部变量互相污染
  extraConfigLua = ''
    do
    ${builtins.readFile ./lua/diagnostics.lua}
    end
    do
    ${builtins.readFile ./lua/autocmds.lua}
    end
  '';

  keymaps = [
    # 折行时按显示行移动
    (bindWith {
      expr = true;
      silent = true;
    } [ "n" "x" ] "j" "v:count == 0 ? 'gj' : 'j'" null)
    (bindWith {
      expr = true;
      silent = true;
    } [ "n" "x" ] "k" "v:count == 0 ? 'gk' : 'k'" null)

    # 窗口
    (remap "n" "<C-h>" "<C-w>h" "Go to Left Window")
    (remap "n" "<C-j>" "<C-w>j" "Go to Lower Window")
    (remap "n" "<C-k>" "<C-w>k" "Go to Upper Window")
    (remap "n" "<C-l>" "<C-w>l" "Go to Right Window")
    (remap "n" "<leader>ww" "<C-W>p" "Other Window")
    (remap "n" "<leader>wq" "<C-W>c" "Delete Window")
    (remap "n" "-" "<C-W>s" "Split Window Below")
    (remap "n" "|" "<C-W>v" "Split Window Right")
    (bind "n" "<C-Up>" "<cmd>resize +2<cr>" "Increase Window Height")
    (bind "n" "<C-Down>" "<cmd>resize -2<cr>" "Decrease Window Height")
    (bind "n" "<C-Left>" "<cmd>vertical resize -2<cr>" "Decrease Window Width")
    (bind "n" "<C-Right>" "<cmd>vertical resize +2<cr>" "Increase Window Width")

    # 移动行
    (bind "n" "<A-j>" "<cmd>m .+1<cr>==" "Move Down")
    (bind "n" "<A-k>" "<cmd>m .-2<cr>==" "Move Up")
    (bind "i" "<A-j>" "<esc><cmd>m .+1<cr>==gi" "Move Down")
    (bind "i" "<A-k>" "<esc><cmd>m .-2<cr>==gi" "Move Up")
    (bind "v" "<A-j>" ":m '>+1<cr>gv=gv" "Move Down")
    (bind "v" "<A-k>" ":m '<-2<cr>gv=gv" "Move Up")

    # 插入模式下在标点处断开 undo
    (bind "i" ";" ";<c-g>u" null)
    (bind "i" "." ".<c-g>u" null)

    (bind [ "i" "x" "n" "s" ] "<C-s>" "<cmd>w<cr><esc>" "Save File")
    (bind [ "i" "n" ] "<esc>" "<cmd>noh<cr><esc>" "Escape and Clear hlsearch")
    (bind "n" "<leader>ur" "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>"
      "Redraw / Clear hlsearch / Diff Update"
    )
    (bind "n" "<leader>qq" "<cmd>qa<cr>" "Quit All")
    (bindLua "n" "<leader>ui" "vim.show_pos" "Inspect Pos")

    # n/N 始终向前/向后搜索
    (expr "n" "n" "'Nn'[v:searchforward].'zv'" "Next Search Result")
    (expr [ "x" "o" ] "n" "'Nn'[v:searchforward]" "Next Search Result")
    (expr "n" "N" "'nN'[v:searchforward].'zv'" "Prev Search Result")
    (expr [ "x" "o" ] "N" "'nN'[v:searchforward]" "Prev Search Result")

    # 诊断
    (bindLua "n" "<leader>cd" "vim.diagnostic.open_float" "Line Diagnostics")
    (diag "]d" 1 null "Next Diagnostic")
    (diag "[d" (-1) null "Prev Diagnostic")
    (diag "]e" 1 "ERROR" "Next Error")
    (diag "[e" (-1) "ERROR" "Prev Error")
    (diag "]w" 1 "WARN" "Next Warning")
    (diag "[w" (-1) "WARN" "Prev Warning")

    # 终端
    (bind "t" "<esc><esc>" "<c-\\><c-n>" "Enter Normal Mode")
    (bind "t" "<C-h>" "<cmd>wincmd h<cr>" "Go to Left Window")
    (bind "t" "<C-j>" "<cmd>wincmd j<cr>" "Go to Lower Window")
    (bind "t" "<C-k>" "<cmd>wincmd k<cr>" "Go to Upper Window")
    (bind "t" "<C-l>" "<cmd>wincmd l<cr>" "Go to Right Window")
    (bind "t" "<C-/>" "<cmd>close<cr>" "Hide Terminal")

    # 标签页
    (bind "n" "<leader><tab><tab>" "<cmd>tabnew<cr>" "New Tab")
    (bind "n" "<leader><tab>l" "<cmd>tabnext<cr>" "Next Tab")
    (bind "n" "<leader><tab>h" "<cmd>tabprevious<cr>" "Previous Tab")
    (bind "n" "<leader><tab>j" "<cmd>tabfirst<cr>" "First Tab")
    (bind "n" "<leader><tab>k" "<cmd>tablast<cr>" "Last Tab")
    (bind "n" "<leader><tab>q" "<cmd>tabclose<cr>" "Close Tab")
  ];
}
