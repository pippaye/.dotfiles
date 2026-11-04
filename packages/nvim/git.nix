let
  inherit (import ./helpers.nix) bind;
in
{
  plugins.lazygit.enable = true;
  keymaps = [ (bind "n" "<leader>gg" "<cmd>LazyGit<CR>" "LazyGit (root dir)") ];

  plugins.gitsigns = {
    enable = true;
    settings = {
      signs = {
        add = {
          text = " ";
        };
        change = {
          text = " ";
        };
        delete = {
          text = " ";
        };
        untracked = {
          text = "";
        };
        topdelete = {
          text = "󱂥 ";
        };
        changedelete = {
          text = "󱂧 ";
        };
      };
    };
  };
}
