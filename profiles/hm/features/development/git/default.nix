{ me, ... }:
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      side-by-side = true;
      line-numbers = true;
      navigate = true;
      syntax-theme = "Nord";
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        inherit (me) name email;
      };
      merge = {
        conflictStyle = "zdiff3";
      };
      pull = {
        rebase = true;
      };
      rebase = {
        autoStash = true;
      };
    };
  };
}
