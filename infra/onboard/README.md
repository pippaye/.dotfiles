# NixOS Onboarding Checklist (Multi-stage)

This repository wires NixOS hosts through `inventory/hosts`, `roles/os`, and host-local configs under `inventory/hosts/nixos/${HOST_ID}`.

Use `infra/onboard/template/` as the **minimum remote-connectable** starter set.

For the complete VPS runbook, including low-memory remote builds, bootstrap cleanup, Docker/DNS/ACME, SOPS, and Home Manager activation, see [`vps.md`](./vps.md).

## Stage 0: Minimal inventory + template (for remote install)

Goal: prepare the smallest set of files to let `nixos-anywhere` install a bootable NixOS with SSH access.

### 0.0 Verify target connectivity
- [ ] Ensure the target is reachable: `ssh -o BatchMode=yes -o ConnectTimeout=10 root@${HOST_IP}`
- [ ] If the host uses a non-standard SSH port, add `-p <port>`.

### 0.1 Pick identity
- [ ] `host-id`: lower-kebab-case (used in flake as `.#${HOST_ID}`)

### 0.2 Create minimal host directory
Copy the template directory and edit it:

```bash
cp -r infra/onboard/template inventory/hosts/nixos/${HOST_ID}
```

Edit the following files in `inventory/hosts/nixos/${HOST_ID}/`:
- `configuration.nix`: imports, hostname, users, SSH, etc.
- `networking.nix`: pick ONE option (DHCP / networkd DHCP / static)
- `disko.nix`: disk layout (required for nix-anywhere + disko)

### 0.3 Register host in inventory
Add a new entry to `inventory/hosts/default.nix`:

```nix
  ${HOST_ID} = {
    system = "x86_64-linux";
    nixosConfig = ./nixos/${HOST_ID};
  };
```

### 0.4 Minimal remote-access checks
- `configuration.nix` must enable `services.openssh.enable = true;`
- Ensure your SSH key is authorized for root or a bootstrap user.

## Stage 1: Remote install (nixos-anywhere)

Run on your local machine from this repo:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config ./inventory/hosts/nixos/${HOST_ID}/hardware-configuration.nix \
  --target-host root@${HOST_IP} \
  --flake .#${HOST_ID}
```

Notes:
- Replace `${HOST_IP}` and `${HOST_ID}`.
- Ensure `disko.nix` is referenced by your host configuration if you use disko.

## Stage 2: NixOS system config
- [ ] Add `role` to `inventory/hosts/default.nix` when you are ready to apply a profile set.
- [ ] Add primary users (if needed) in `inventory/hosts/nixos/${HOST_ID}/users.nix`.
- [ ] Adjust `inventory/hosts/nixos/${HOST_ID}/configuration.nix` (services, users, bootloader).
- [ ] Adjust `networking.nix` if the provider requires static config.
- [ ] Finetune default options:
    - `profiles/os/common/services/timesyncd.nix`: `services.timesyncd.servers` (default CN NTP servers).
    - `profiles/os/common/base-system/i18n.nix`: set `time.timeZone` explicitly for VPS; common values: `Asia/Shanghai`, `Asia/Hong_Kong`, `Asia/Singapore`, `Asia/Tokyo`, `Asia/Seoul`, `Asia/Kolkata`, `Europe/London`, `Europe/Berlin`, `Europe/Amsterdam`, `Europe/Paris`, `Europe/Moscow`, `America/New_York`, `America/Chicago`, `America/Denver`, `America/Los_Angeles`, `America/Toronto`, `Australia/Sydney`.
    - Time zone lookup helpers: `timedatectl list-timezones | rg -i '<city|region>'`, `timedatectl list-timezones | rg -i '<country|continent>'`
    - ...
- [ ] Enable host-side SOPS (via role or by importing `profiles/os/common/nix-settings/sops.nix`).
- [ ] SOPS host key pipeline (copy/paste):
```bash
age-keygen -o /tmp/age.key
ssh root@${HOST_IP} 'install -d -m 0700 /var/lib/sops-nix'
scp /tmp/age.key root@${HOST_IP}:/var/lib/sops-nix/keys.txt
ssh root@${HOST_IP} 'chmod 0400 /var/lib/sops-nix/keys.txt'
awk '/public key:/{print $4}' /tmp/age.key
# add the public key into .sops.yaml
sops updatekeys ${SECRETS_FILE}
```
- [ ] Apply: `sudo nixos-rebuild switch --flake .#${HOST_ID} --target-host root@${HOST_IP}`.
- [ ] Set passwords on the target: `ssh root@${HOST_IP} 'passwd root'` and `ssh root@${HOST_IP} 'passwd ashenye'`.


## Stage 3: Home Manager
- [ ] Add user entry to `inventory/users/default.nix`.
- [ ] Create `inventory/users/home-manager/${HOST_ID}.nix` if needed.
- [ ] Add SSH config stub at `inventory/users/ssh-configs/${HOST_ID}.nix`.
- [ ] Enable user-side SOPS (via HM profile import or by adding `profiles/hm/nix/sops.nix`).
- [ ] User SOPS key pipeline (copy/paste):
```bash
ssh root@${HOST_IP} "install -d -m 0700 -o ${USER} -g users /home/${USER}/.config/sops/age"
ssh root@${HOST_IP} "age-keygen -o /home/${USER}/.config/sops/age/keys.txt"
ssh root@${HOST_IP} "chown ${USER}:users /home/${USER}/.config/sops/age/keys.txt"
ssh root@${HOST_IP} "chmod 0400 /home/${USER}/.config/sops/age/keys.txt"
ssh root@${HOST_IP} "age-keygen -y /home/${USER}/.config/sops/age/keys.txt"
# add the public key into .sops.yaml under users as ${USER}@${HOST_ID}
sops updatekeys ${SECRETS_FILE}
```
- [ ] Apply remotely: `ssh ${USER}@${HOST_IP} 'home-manager switch --flake ".#${USER}@${HOST_ID}" -b bak'`.

## Stage 4: Validation
- [ ] Cleanup: remove temporary convenience settings from `infra/onboard/template/finetune.nix` after onboarding (e.g. root login, password auth, SSH port 22, extra packages).
- [ ] Validate services, networking, and SSH access.
- [ ] Optional: `nix flake check`.

## Stage 5: Infra Integration
- [ ] SSH topology: update `inventory/topology/ssh.nix` to wire the new host into the graph.
- [ ] deploy-rs: update `infra/remote-deploy/default.nix` (when re-enabled).
- [ ] DNS binding: update the relevant inventory topology DNS records (e.g. `inventory/topology/networks/void.nix`).
- [ ] Remote build: add/remove builders under `infra/remote-builder` and any host config imports that enable it.

## Notes
- This repo often uses SSH port `2222`; adjust if your host differs.
- Keep host/user-specific logic in `inventory/` and wire it through roles/profiles.
