{ lib, isDarwin, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    history = {
      size = 10000;
      ignoreAllDups = true;
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "wd"
        "history"
        "extract"
        "systemd"
        "fzf"
      ];
      extraConfig = ''
        COMPLETION_WAITING_DOTS=true
      '';
    };
    shellAliases = {
      lg = "lazygit";
      ld = "lazydocker";
      ls = "lsd --hyperlink=auto";
      v = "nvim";
      vi = "nvim";
      vim = "nvim";
      e = "printenv";
      o = "xdg-open";
      j = "just";
      s = "ssh";
      sc = "systemctl";
      scs = "systemctl status";
      sce = "systemctl edit";
      scsta = "systemctl start";
      scsto = "systemctl stop";
      scc = "systemctl cat";
      jc = "journalctl";
      jcu = "journalctl -u";
      jcfu = "journalctl -fu";
      jcexu = "journalctl -exu";
      pd = "podman";
      pdr = "podman run";
      pdb = "podman build";
      pde = "podman exec";
      pdc = "podman compose";
      pdv = "podman volume";
      fire = "systemd-run";
      fireu = "systemd-run --user";
      iat = "kitty +kitten icat";
      ac = "source .venv/bin/activate";
      de = "deactivate";
      zl = "zellij";
      zs = "zellij -s";
      za = "zellij attach";
      zd = "zellij delete-session";
      zls = "zellij list-sessions";
      zda = "zellij delete-all-sessions";
      tl = "tldr";
      ks = "kitten ssh";
      cx = "codex";
      cxr = "codex resume";
      cxy = "codex --yolo";
      d = "docker";
      dr = "docker run";
      ds = "docker stop";
      drm = "docker rm";
      kt = "kitty transfer";
      rs = "rsync -avzhP";
      rsd = "rsync -avzhP --dry-run";
      rsm = "rsync -avzhP --delete";
      rsf = "rsync -avhP";
      pj = "cd ~/repo/$(ls ~/repo | fzf)";
      calc = "python3 -ic 'import math; from math import *'";
      cl = "claude";
      b = "bat";
      cs = "cheatsheet";
    };
    initContent = lib.concatStrings (
      [ (builtins.readFile ./init_content.sh) ]
      ++ (lib.optionals isDarwin [
        ''
          eval "$(/opt/homebrew/bin/brew shellenv)"
        ''
      ])
    );
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      direnv.disabled = false;
      directory = {
        truncation_symbol = "…/";
        truncate_to_repo = false;
      };
      git_metrics.disabled = false;
      git_status = {
        diverged = "⇡$ahead_count⇣$behind_count";
        conflicted = "=$count";
        ahead = "⇡$count";
        behind = "⇣$count";
        untracked = "?$count";
        stashed = "+$count";
        modified = "!$count";
        staged = "\\$$count";
        renamed = "»$count";
        deleted = "✘$count";
      };
      localip = {
        ssh_only = false;
        disabled = false;
      };
      memory_usage.disabled = false;
      os.disabled = false;
      shell.disabled = false;
      shlvl.disabled = false;
      status.disabled = false;
      sudo.disabled = false;
      time.disabled = false;
      continuation_prompt = "▶▶ ";
      fill.symbol = " ";
      format = "$os$all";
    };
  };
}
