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

# one-time: create the self-signed cert used to sign kitty.app on darwin
# (see docs/kitty-darwin-codesign.md). Idempotent.
kitty-darwin-codesign-init:
    #!/usr/bin/env bash
    set -euo pipefail
    dir=/var/lib/kitty-darwin-codesign
    repo_cert=overlays/kitty-darwin-codesign/cert.pem
    if ! sudo test -e "$dir/key.pem"; then
      tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
      (
        umask 077; cd "$tmp"
        printf '%s\n' '[req]' 'distinguished_name=dn' 'x509_extensions=ext' 'prompt=no' \
          '[dn]' 'CN=kitty-darwin-codesign' \
          '[ext]' 'basicConstraints=critical,CA:false' 'keyUsage=critical,digitalSignature' \
          'extendedKeyUsage=critical,codeSigning' 'subjectKeyIdentifier=hash' > cert.cnf
        /usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -keyout raw.pem -out cert.pem -days 36500 -config cert.cnf 2>/dev/null
        # rcodesign wants PKCS#8
        /usr/bin/openssl pkcs8 -topk8 -nocrypt -in raw.pem -out key.pem
      )
      sudo install -d -o root -g wheel -m 0755 "$dir"
      sudo install -o root -g nixbld -m 0640 "$tmp/key.pem" "$dir/key.pem"
      sudo install -o root -g wheel -m 0644 "$tmp/cert.pem" "$dir/cert.pem"
      echo "generated $dir/key.pem"
    fi
    mkdir -p "$(dirname "$repo_cert")"
    cp "$dir/cert.pem" "$repo_cert"
    git add "$repo_cert"
    /usr/bin/openssl x509 -in "$repo_cert" -noout -subject -fingerprint -sha1
    echo "back up $dir/key.pem somewhere safe: losing it means re-granting all kitty permissions."

