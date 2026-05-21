{ paths, ... }:
let
  inherit (paths) hmProfiles hmQuirks infra;
in
{
  imports = [
    "${hmQuirks}/github-access-limits.nix"
    "${hmProfiles}/common"
    "${hmProfiles}/nix/sops.nix"
    "${hmProfiles}/features/browsers/zen"
    "${hmProfiles}/features/development"
    "${hmProfiles}/features/downloading/bittorrent.nix"
    "${hmProfiles}/features/downloading/aria2.nix"
    "${hmProfiles}/features/gaming/minecraft.nix"
    "${hmProfiles}/features/knowledge"
    "${hmProfiles}/features/llms/codex"
    "${hmProfiles}/features/llms/gemini"
    "${hmProfiles}/features/viewers/mpv"
    # FIX "${hmProfiles}/features/viewers/zathura.nix"
    "${infra}/ssh"
  ];
  hmProfiles.dev.daily = true;
  hmProfiles.dev.lite = false;
}
