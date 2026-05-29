{ paths, ... }:
let
  inherit (paths) osProfiles hmProfiles;
in
{
  imports = [
    "${osProfiles}/common"
    "${osProfiles}/preferences/std"
    "${osProfiles}/utils/std"
    "${osProfiles}/nix/garbage-collector.nix"
    "${hmProfiles}/features/integration/kdeconnect/expose-ports.nix"
    # "${osProfiles}/features/downloading/aria2.nix"
    "${osProfiles}/desktop"
    "${osProfiles}/features/development/wireshark.nix"
    "${osProfiles}/features/virtualisation/podman.nix"
    "${osProfiles}/hardware/gaomon.nix"
    "${osProfiles}/hardware/network-printers.nix"
    "${osProfiles}/nix/nix-index.nix"
  ];
}
