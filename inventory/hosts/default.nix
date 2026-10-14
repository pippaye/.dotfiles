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
  bambu = {
    role = "dog";
    tags = [
      "nixos"
    ];
    nixosConfig = ./nixos/bambu;
  };
  lime = {
    role = "dog";
    tags = [
      "nixos"
      "vps"
    ];
    nixosConfig = ./nixos/lime;
  };
  yuzu = {
    role = "dog";
    priUser = "ashenye";
    tags = [
      "nixos"
      "vps"
    ];
    nixosConfig = ./nixos/yuzu;
  };
}
