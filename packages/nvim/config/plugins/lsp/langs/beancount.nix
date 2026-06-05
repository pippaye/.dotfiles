{ lib, pkgs, ... }:
{

  plugins.lsp.servers = {
    beancount.enable = true;
  };
}
