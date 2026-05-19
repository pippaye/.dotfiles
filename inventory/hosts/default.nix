{ paths, ... }:
{
  lan = {
    role = "cat";
    priUser = "ashenye";
    alias = [
      "desk00"
      "u265kf"
    ];
    tags = [
      "nixos"
    ];
    nixosConfig = {
      main = ./nixos/lan;
      extra = [
        "${paths.osQuirks}/fix-fn-keys.nix"
        "${paths.osQuirks}/fix-fcitx5-svg-show-nothing.nix"
      ];
    };
  };
  mume = {
    role = "hermit";
    tags = [
      "darwin"
    ];
    darwinConfig = ./darwin/mume;
  };
  citrus = {
    role = "dog";
    tags = [
      "nixos"
      "vps"
    ];
    alias = [
      "vps00"
    ];
    nixosConfig = ./nixos/citrus;
  };
  lemon = {
    role = "dog";
    tags = [
      "nixos"
      "vps"
    ];
    alias = [
      "vps01"
    ];
    nixosConfig = ./nixos/lemon;
  };
  yuzu = {
    role = "dog";
    tags = [
      "nixos"
      "vps"
    ];
    alias = [
      "vps02"
    ];
    nixosConfig = ./nixos/yuzu;
  };
  bambu = {
    role = "dog";
    tags = [
      "nixos"
    ];
    nixosConfig = ./nixos/bambu;
  };
}
