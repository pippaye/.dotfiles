{ lib, lite, ... }:
{
  # Import all config modules
  imports = [
    ./options.nix
    ./keymaps.nix
    ./autocommands.nix
    ./plugins
  ];

  # Performance
  performance = {
    byteCompileLua.enable = true;
  };

  # FIXIT 生成doc依赖pandoc, 需要lua
  # Nixvim's manpage build currently requires a pandoc build with Lua support.
  enableMan = false;

  # Aliases
  viAlias = true;
  vimAlias = true;
}
