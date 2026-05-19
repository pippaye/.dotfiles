{ paths, ... }:
let
  inherit (paths) osProfiles infra;
in
{
  imports = [
    "${osProfiles}/hardware/nvidia-daily.nix"
    "${osProfiles}/hardware/xm5.nix"
    "${osProfiles}/features/streaming/sunshine.nix"
    "${osProfiles}/features/gaming/steam.nix"
    "${infra}/remote-builder/server.nix"
    "${infra}/remote-deploy/deployee.nix"
    ./disko.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./users.nix
    ./fine-tuning.nix
    ./nspawn.nix
    ./services.nix
    ./adhoc.nix
  ];
  config.boot.extraModprobeConfig = ''
    options nvidia NVreg_RestrictProfilingToAdminUsers=0
  '';
}
