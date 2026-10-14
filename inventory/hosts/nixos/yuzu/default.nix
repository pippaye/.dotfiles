{ paths, ... }:
let
  inherit (paths) infra osProfiles;
in
{
  imports = [
    "${infra}/remote-deploy/deployee.nix"
    "${osProfiles}/vps"
    ./hardware-configuration.nix
    ./fine-tuning.nix
    ./networking.nix
    ./users.nix
    ./services.nix
    ./disko.nix
  ];
}
