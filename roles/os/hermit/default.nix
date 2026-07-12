{ paths, ... }:
# 孤独的小寄居蟹nix-darwin, 寄生在macOS上
let
  inherit (paths) osProfiles;
in
{
  imports = [
    "${osProfiles}/common/nix-settings/nix.nix"
    "${osProfiles}/preferences/std"
    "${osProfiles}/utils/std"
    "${osProfiles}/nix/garbage-collector.nix"
    "${osProfiles}/nix/nix-index.nix"
    ./adhoc.nix
  ];
}
