default:
    just --list

deploy-nixos:
    sudo nixos-rebuild switch --flake $(pwd)#$(hostname)
deploy-home:
    home-manager switch --flake "$(pwd)#$(id -un)@$(hostname)" -b bak
deploy-both: deploy-nixos deploy-home

deploy-darwin:
    sudo darwin-rebuild switch


update-flake:
    nix flake update

# 1.运行deploy生成密钥 2.把生成的密钥添加到文件.sops.yaml 3.更新密钥文件
update-sops $SOPS_AGE_KEY path-to-file:
    nix-shell -p sops --run 'sops updatekeys --yes {{ path-to-file }}'

clean older-than:
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than {{ older-than }}

# garbage collect all unused nix store entries
gc:
    sudo nix store gc --debug
    sudo nix-collect-garbage --delete-old

# generate a new age key

# sops default lookup path $XDG_CONFIG_HOME/sops/age/key.txt
gen-age-key path:
    mkdir -p $(dirname {{ path }})
    nix-shell -p age --run 'age-keygen -o {{ path }}'

# print host age-key
get-host-age-key:
    @sudo grep '^AGE-SECRET-KEY' /var/lib/sops-nix/keys.txt

fmt:
    nix fmt **/*.nix

