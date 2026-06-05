  { lib, pkgs, ... }:
  {
    filetype.extension = {
      bean = "beancount";
      beancount = "beancount";
    };

    plugins.lsp.servers.beancount = {
      enable = true;

      rootMarkers = [
        "main.beancount"
        "main.bean"
        ".git"
      ];

      extraOptions = {
        init_options = {
          journal_file = "main.beancount";

          diagnostic_flags = [ "!" ];

          completion = {
            fuzzy_match_accounts = true;
          };

        };
      };
    };
  }