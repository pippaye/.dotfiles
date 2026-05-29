{ paths, ... }:
let
  inherit (paths) osProfiles;
in
{
  imports = [
    "${osProfiles}/hardware/wireless.nix"
  ];
  networking.useDHCP = true;
}
