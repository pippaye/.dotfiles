# NixOS VPS Onboarding Runbook

这份文档记录一台全新 VPS 从现有 Linux 系统切换到本仓库 NixOS 的完整流程。示例使用 BIOS + 单盘 MBR VPS；UEFI、DHCP 和多盘机器需要按实际硬件调整。

## 0. 风险和前提

`nixos-anywhere` 会清空 disko 配置中声明的磁盘。执行前必须确认目标磁盘、网卡、IP、网关和启动模式。

需要准备：

- root SSH 或 root 密码
- 本机管理公钥
- 目标公网 IP、网关、前缀长度、DNS
- 目标的启动模式：BIOS 或 UEFI
- 目标时区
- 目标磁盘设备，例如 `/dev/sda`

## 1. 探测目标机

先从现有系统收集事实，不要猜测网卡名或磁盘名：

```bash
ssh -o BatchMode=yes -o ConnectTimeout=10 root@${HOST_IP} \
  'uname -a; cat /etc/os-release; \
   test -d /sys/firmware/efi && echo boot=efi || echo boot=bios; \
   lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,MOUNTPOINTS; \
   ip -br addr; ip route'
```

还应记录：

```bash
ssh root@${HOST_IP} \
  'cat /etc/network/interfaces 2>/dev/null; \
   cat /sys/class/net/*/address 2>/dev/null; \
   nproc; free -h'
```

静态 VPS 至少要确认：

- 网卡名称，例如 `ens18`
- IPv4 地址和前缀，例如 `210.121.44.78/24`
- 网关，例如 `210.121.44.1`
- DNS 服务器
- 磁盘，例如 `/dev/sda`
- BIOS/UEFI

## 2. 创建主机清单

主机目录通常包含：

```text
inventory/hosts/nixos/${HOST_ID}/
├── default.nix
├── disko.nix
├── fine-tuning.nix
├── hardware-configuration.nix
├── networking.nix
├── services.nix
└── users.nix
```

`default.nix` 应组合仓库现有 profile 和主机文件：

```nix
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
```

在 `inventory/hosts/default.nix` 注册主机：

```nix
${HOST_ID} = {
  role = "dog";
  tags = [
    "nixos"
    "vps"
  ];
  nixosConfig = ./nixos/${HOST_ID};
};
```

VPS 用户通常在 `inventory/users/default.nix` 注册：

```nix
"ashenye@${HOST_ID}" = {
  role = "dog";
  tags = [ "vps" ];
  sshPubKey = "<user-public-key>";
  sshConfig = ./ssh-configs/${HOST_ID}.nix;
};
```

`role = "dog"` 已经提供默认 Home Manager 环境，不需要为了普通 VPS 创建空的主机专用 HM 文件。

## 3. 磁盘、硬件和网络

BIOS + MBR + 单盘 XFS 的 disko 示例：

```nix
{ inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices.disk.main = {
    device = "/dev/sda";
    type = "disk";
    content = {
      type = "table";
      format = "msdos";
      partitions = [
        {
          name = "root";
          part-type = "primary";
          start = "1M";
          end = "100%";
          bootable = true;
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/";
          };
        }
      ];
    };
  };
}
```

BIOS 主机的硬件配置至少需要：

```nix
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
```

正式主机配置中保留引导器设置，但使用当前选项名：

```nix
{
  osProfiles.common.bootloader = "grub";
  boot.loader.grub.devices = [ "/dev/sda" ];
}
```

不要再使用旧的 `boot.loader.grub.device`；当前 nixpkgs 要求 `devices` 或 `mirroredBoots`。

静态网络示例：

```nix
{ ... }:
{
  networking = {
    nameservers = [ "8.8.8.8" "1.1.1.1" ];
    defaultGateway = {
      address = "<gateway>";
      interface = "<interface>";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = true;
    interfaces.<interface>.ipv4.addresses = [
      {
        address = "<ipv4>";
        prefixLength = 24;
      }
    ];
  };
}
```

## 4. Bootstrap 配置

Bootstrap 只负责让 `nixos-anywhere` 能连接和安装。临时设置可以包括：

- root 管理公钥
- 临时 root 登录
- 临时 SSH 端口 22
- 临时诊断工具

Bootstrap 配置不能成为最终状态。安装完成后应删除：

```nix
users.users.root.openssh.authorizedKeys.keys = [ ... ];
environment.systemPackages = with pkgs; [ vim git htop ];
services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
services.openssh.settings.PasswordAuthentication = lib.mkForce false;
services.openssh.ports = [ 22 ];
```

清理后使用公共 profile 的默认 SSH 端口 `2222`，并由普通管理用户登录。为了避免关闭 root 后失去管理权限，管理用户必须同时具备：

- 公钥登录
- `wheel` 组
- 密码已设置，或明确的 NOPASSWD sudo 规则

`system.stateVersion` 不属于 bootstrap 设置。它由 `profiles/os/common/nix-settings/nix.nix` 统一声明，主机文件不应重复配置。

时区必须根据实际目标确认后设置，例如：

```nix
time.timeZone = "Asia/Seoul";
```

不要因为 IP、供应商或当前系统语言而猜测时区。

## 5. Flake 评估和安装

Nix flake 默认不会读取未被 Git 跟踪的新文件。首次评估前至少暂存新主机目录：

```bash
git add inventory/hosts/default.nix \
  inventory/hosts/nixos/${HOST_ID} \
  inventory/users/default.nix \
  inventory/users/ssh-configs/${HOST_ID}.nix

git diff --check
nix flake check --no-build
```

执行安装：

```bash
nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config \
    ./inventory/hosts/nixos/${HOST_ID}/hardware-configuration.nix \
  --target-host root@${HOST_IP} \
  --flake .#${HOST_ID}
```

该命令会清空 disko 指定的磁盘。安装完成后目标机会重启，SSH host key 通常会变化，需要更新本机 `known_hosts`：

```bash
ssh-keygen -R ${HOST_IP}
ssh-keyscan -H -t ed25519 ${HOST_IP} >> ~/.ssh/known_hosts
```

### kexec 连接中断

kexec 阶段会主动重启 SSH，短暂断开是正常的。如果工具最终报告 `Kexec failed`，先用目标 root 密码登录临时 `nixos-installer` 环境，安装本机公钥：

```bash
SSHPASS='<password>' sshpass -e ssh \
  -o PreferredAuthentications=password \
  -o PubkeyAuthentication=no \
  root@${HOST_IP} \
  'install -d -m 0700 /root/.ssh && \
   printf "%s\\n" "<public-key>" > /root/.ssh/authorized_keys && \
   chmod 0600 /root/.ssh/authorized_keys'
```

确认临时环境可用后，可跳过 kexec 重新执行：

```bash
nix run github:nix-community/nixos-anywhere -- \
  --phases=disko,install,reboot \
  --generate-hardware-config nixos-generate-config \
    ./inventory/hosts/nixos/${HOST_ID}/hardware-configuration.nix \
  --target-host root@${HOST_IP} \
  -i ~/.ssh/id_ed25519 \
  --flake .#${HOST_ID}
```

## 6. 低配 VPS 的系统部署

2G VPS 上从 Darwin 直接使用 `--target-host --build-host` 复制整个闭包，可能导致远程 SSH banner 超时。更稳定的方式是先同步仓库，在目标机本地构建：

```bash
tar --exclude='./.git' --exclude='./result*' -cf - . | \
  ssh root@${HOST_IP} \
    'rm -rf /root/dotfiles && \
     mkdir -p /root/dotfiles && \
     tar -xf - -C /root/dotfiles'

ssh root@${HOST_IP} \
  'nixos-rebuild switch --flake /root/dotfiles#${HOST_ID}'
```

清理 root/22 bootstrap 配置后，从 `2222` 端口用管理用户重新连接，再同步 Home Manager 配置。

## 7. Docker、域名、反向代理和 ACME

主机服务文件示例：

```nix
{ ... }:
{
  virtualisation.docker.enable = true;
  users.users.ashenye.extraGroups = [ "docker" ];

  infra.dnsctl = {
    ipv4 = "<ipv4>";
    domain = "pippaye.top";

    nginxVirtualHosts.example.locations."/" = {
      proxyPass = "http://127.0.0.1:38001";
    };
  };
}
```

这会生成：

- `${HOST_ID}.pippaye.top` 的 A 记录模型
- `example.pippaye.top` 到 `${HOST_ID}.pippaye.top` 的 CNAME 模型
- Nginx HTTPS virtual host
- ACME 证书申请服务

`infra/dnsctl` 只负责从 NixOS 配置建模和收集 DNS 记录，不会自动修改 Cloudflare。必须使用仓库现有的 `nixdnsctl` 发布流程，或通过 Cloudflare API 创建对应的 A/CNAME 记录。

先发布 DNS，再检查证书：

```bash
dig +short ${HOST_ID}.pippaye.top A
dig +short example.pippaye.top A
ssh -p 2222 ${USER}@${HOST_IP} \
  'sudo systemctl restart acme-order-renew-example.pippaye.top.service'
```

如果 ACME 日志出现 `NXDOMAIN`，优先检查 DNS 记录是否已经发布，而不是反复重启 Nginx。

## 8. Home Manager 和用户 SOPS

`role = "dog"` 会加载默认 Home Manager 环境。主机用户注册后，生成用户 age key：

```bash
ssh -p 2222 ${USER}@${HOST_IP} \
  'mkdir -p ~/.config/sops/age && \
   chmod 0700 ~/.config/sops/age && \
   test -e ~/.config/sops/age/keys.txt || \
   age-keygen -o ~/.config/sops/age/keys.txt && \
   chmod 0400 ~/.config/sops/age/keys.txt && \
   age-keygen -y ~/.config/sops/age/keys.txt'
```

把输出的公钥加入 `.sops.yaml`，并加入用户实际需要读取的规则。`dog` 默认开发环境会读取 `secrets/api-tokens.yaml`，通常至少需要更新 `secrets/default.yaml` 和 `secrets/api-tokens.yaml`：

```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  sops updatekeys --yes secrets/default.yaml
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  sops updatekeys --yes secrets/api-tokens.yaml
```

同步仓库到用户目录后，以用户身份执行 Home Manager：

```bash
ssh -p 2222 ${USER}@${HOST_IP} \
  'nix run nixpkgs#home-manager -- switch \
     --flake /home/${USER}/dotfiles#${USER}@${HOST_ID} -b bak'
```

不要在已经是普通用户的 SSH 会话中再次调用 `runuser`；直接运行 `nix run ... home-manager` 即可。

## 9. 最终验证

```bash
ssh -p 2222 ${USER}@${HOST_IP} 'id; sudo -n true; timedatectl show -p Timezone --value'
ssh -p 2222 ${USER}@${HOST_IP} \
  'sudo sshd -T | grep -E "^(port|permitrootlogin|passwordauthentication) "'
ssh -p 2222 ${USER}@${HOST_IP} \
  'sudo systemctl is-active docker nginx fail2ban; \
   sudo systemctl --failed --no-legend; \
   sudo docker --version'
ssh -p 2222 ${USER}@${HOST_IP} \
  'home-manager generations | head -3; \
   systemctl --user status sops-nix.service --no-pager --lines=8'
```

期望结果：

- 管理用户可以通过 `2222` 登录并执行 sudo
- `PermitRootLogin` 为 `no`
- `PasswordAuthentication` 为 `no`
- 时区是已经确认的值
- Docker、Nginx、Fail2ban 正常
- failed systemd units 为空
- Home Manager 有 current generation
- `sops-nix.service` 执行成功
- DNS 已发布后 ACME 证书申请成功

## 10. 最终清理清单

- [ ] 主机文件不重复声明 `system.stateVersion`
- [ ] 删除 root bootstrap 公钥和 `PermitRootLogin = "yes"`
- [ ] 删除 `PasswordAuthentication` 和临时 SSH `22` 端口覆盖
- [ ] 删除模板中的临时工具包
- [ ] 保留正式的 GRUB、磁盘、网络、Docker、DNS 和时区配置
- [ ] 管理用户拥有公钥登录和明确的 sudo 权限
- [ ] `.sops.yaml` 和加密文件包含新用户 age 公钥
- [ ] Home Manager 已激活
- [ ] DNS 和 ACME 已验证
- [ ] `nix flake check --no-build` 已通过
