{ pkgs, ... }:
{
  home.packages = with pkgs; [
    beancount
    fava
  ];
}
