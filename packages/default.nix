{ pkgs, inputs, ... }:
{
  fonts = pkgs.callPackage ./my-fonts.nix {
    url = "https://nix-blob.pippaye.top/fonts.zip";
    hash = "sha256-/1ryVz2fcIOftsUjPCuQI5zMmtNJE3g4AUf92Zwux8o=";
  };
  wallpapers = pkgs.callPackage ./my-wallpapers.nix {
    url = "https://nix-blob.pippaye.top/wallpapers.zip";
    hash = "sha256-fAluh/9f2MkxkPTGTzaycMWuAr0jh6bPZ2e9Itx94eY=";
  };
  zju-connect = pkgs.callPackage ./zju-connect.nix { };
  gnome-terminal = pkgs.callPackage ./gnome-terminal.nix { };
  retro-crt = pkgs.callPackage ./retro-crt.nix { };
  downloader = pkgs.callPackage ./downloader { };
  ensure-exist = pkgs.callPackage ./ensure-exist { };
  fuck = pkgs.callPackage ./fuck { };
  # Neovim packages
  nvim = pkgs.callPackage ./nvim {
    inherit inputs;
    lite = false;
  };
  nvim-lite = pkgs.callPackage ./nvim {
    inherit inputs;
    lite = true;
  };
}
