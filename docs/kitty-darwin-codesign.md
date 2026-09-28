# kitty-darwin-codesign：nixpkgs 版 kitty 在 macOS 上无法发通知、每次更新都要重新授权

- 适用环境：macOS 26（Darwin 25）、aarch64-darwin，kitty 0.49.0 来自 nixpkgs，由 Home Manager `copyApps` 安装到 `~/Applications/Home Manager Apps`
- 修复代码：[`overlays/kitty-darwin-codesign/`](../overlays/kitty-darwin-codesign/)（overlay + 签名证书）
- 初始化命令：`just kitty-darwin-codesign-init`
- 私钥：`/var/lib/kitty-darwin-codesign/key.pem`

以上三处统一使用 `kitty-darwin-codesign` 这个名字（格式为 `<包>-<平台>-<用途>`，和 `overlays/kitty-darwin-no-branch-protection.patch` 一致）。

## 现象

在 kitty 里执行：

```sh
printf '\x1b]99;;Hello world\x1b\\'
```

没有任何通知，也没有授权弹窗。「系统设置 → 通知」里找不到 kitty，没有开关可以打开。
`notify_on_cmd_finish` 同样不生效。

> 注：`OSC 99` 是 kitty 的桌面通知协议；`OSC 52` 是剪贴板协议，两者无关。

系统日志（`log show`）里 kitty 进程的报错：

```
[net.kovidgoyal.kitty] Requested authorization [ didGrant: 0 hasError: 1 ... ]
Failed to request permission for showing notification: (UNErrorDomain error 1.)
```

`UNErrorDomain error 1` 是 `UNErrorCodeNotificationsNotAllowed`，系统在询问用户之前就拒绝了请求。

## 根因

问题有两层，分别对应两个系统守护进程。

### 1. 签名标识和 Bundle ID 不一致，被 `usernotificationsd` 拒绝

nixpkgs 构建 kitty.app 时，`autoSignDarwinBinariesHook` 只给每个 Mach-O 文件单独做 ad-hoc 签名：

```
$ codesign -dv kitty.app
Identifier=kitty                  # 不是 net.kovidgoyal.kitty
Signature=adhoc
Info.plist=not bound              # Info.plist 没有被签名绑定
Sealed Resources=none             # 整个 bundle 没有被封装签名
```

实际运行的进程是 `wrapProgram` 生成的 `Contents/MacOS/.kitty-wrapped`，它的签名标识是 `.kitty-wrapped`。
`usernotificationsd` 发现调用方的签名标识和它声称的 Bundle ID `net.kovidgoyal.kitty` 不一致，就直接拒绝：

```
usernotificationsd: [.kitty-wrapped] Entitlement 'com.apple.private.usernotifications.bundle-identifiers' required to request user notifications
usernotificationsd: [.kitty-wrapped] requestAuthorization not allowed: net.kovidgoyal.kitty
```

签名正确时，这里的日志是 `Entitlement check success: matching bundle identifiers`。

### 2. 已经问过的 Bundle ID 不会再弹窗（`usernoted`）

`usernoted` 会记住它对某个 Bundle ID 发起过授权询问。弹窗如果被关掉，或者大约 2 分钟没有应答而自动消失，之后这个 ID 的所有请求都会直接返回
`Notifications are not allowed for this application`，而且：

- 不会再弹窗；
- 在 `~/Library/Preferences/com.apple.ncprefs.plist` 和「系统设置 → 通知」里都没有条目，所以没法手动打开；
- 重启 `usernoted` 也不能恢复。它的数据在 `~/Library/Group Containers/group.com.apple.usernoted/`，受 TCC 保护，没法直接清理。

在这台机器上，`net.kovidgoyal.kitty` 和 `net.kovidgoyal.kitty.nix` 都已经卡在这个状态。**只修签名还不够，必须同时换一个没用过的 Bundle ID。**

### 排查过程中排除掉的方向

- **"只有 Apple 签名的 App 才能发通知"：不成立。** 最早的对照实验把测试 App 放在 `/tmp` 下，`usernoted` 找不到它（`Failed to find or validate client`），导致误判。放到 `~/Applications` 后，ad-hoc 签名的 App 可以正常弹出授权窗口。
- **LaunchServices 里的旧注册：不是根因。** 之前系统里注册了 9 条 `net.kovidgoyal.kitty`，都是旧 store 路径和临时目录，已经用 `lsregister -u` 清理，但清理后仍然被拒。
- **能不能弹窗和证书无关。** 自签名证书和 ad-hoc 签名在这一点上表现相同，决定成败的是上面两点。
  但证书决定了**授权能不能跨构建保留**，见下一节。

### 3. 为什么每次更新都要重新授权：ad-hoc 签名只能按 cdhash 识别

TCC（完全磁盘访问、辅助功能、屏幕录制等）和 usernoted 保存授权时，会同时记下 App 的 *designated requirement*（DR，指定要求），用它判断以后运行的是不是"同一个 App"。

- **ad-hoc 签名**没有证书，DR 只能写成 `cdhash H"…"`，也就是代码哈希。每次重新构建哈希都会变，系统就把它当成新 App。
  tccd 日志里的 `Failed to match existing code requirement for subject net.kovidgoyal.kitty` 说的就是这个。
  当时 kitty 在 `ScreenCapture`、`SystemPolicyAllFiles`、`DownloadsFolder`、`Photos`、`MediaLibrary` 等权限上都因此反复弹窗。
- **用固定证书签名**时，DR 是 `identifier "<bundleId>" and certificate root = H"<证书哈希>"`，只和 Bundle ID 以及证书有关，和代码内容无关。
  kitty 怎么升级、怎么重新构建，DR 都不变，已经授予的权限一直有效。

证书是自签名的也没关系。amfid 会记一条 `signed by an unknown certificate chain`，但这不影响启动（已实测）；TCC 只比对 DR，不要求证书链受信任。

## 修复方案

在 overlay 里给 `kitty` 追加一个 `postFixupHooks`。它排在 nixpkgs 自带的 `autoSignDarwinBinariesHook` 之后执行，做以下几件事：

1. 用 `PlistBuddy` 把 `CFBundleIdentifier` 改成新的 ID（当前是 `net.kovidgoyal.kitty.nixpkgs`）；
2. 用 nixpkgs 里的 `rcodesign` 和**固定的自签名证书**给整个 bundle 签名：
   - `.kitty-wrapped`（实际运行的进程）和 `kitty`（wrapper，即 bundle 的主可执行文件）使用 Bundle ID 作为签名标识；
   - `kitten`、`kitty-quick-access.app` 也一起签名；
   - Info.plist 和资源文件都封装进签名。
3. 构建时检查：`codesign --verify --deep --strict` 通过、DR 的形式是 `identifier … and certificate root`、`.kitty-wrapped` 的签名标识正确。任何一项不满足，构建都会失败。

修复后的签名：

```
$ codesign -d -r- kitty.app
designated => identifier "net.kovidgoyal.kitty.nixpkgs" and certificate root = H"…"
$ codesign -dvv kitty.app/Contents/MacOS/.kitty-wrapped
Identifier=net.kovidgoyal.kitty.nixpkgs
Authority=kitty-darwin-codesign
```

已验证：两次不同的构建（cdhash 不同）互相满足对方的 DR，所以权限会保留。

### 证书和私钥

| 文件 | 位置 | 说明 |
| --- | --- | --- |
| 证书（公开） | `overlays/kitty-darwin-codesign/cert.pem` | 提交进仓库，会进入 derivation 哈希 |
| 私钥 | `/var/lib/kitty-darwin-codesign/key.pem` | 不进 nix store，也不进仓库。权限是 `root:nixbld 0640`，构建时由 nixbld 用户读取 |

用 `just kitty-darwin-codesign-init` 生成（需要 sudo，可以重复执行）。
私钥丢了可以重新生成，代价是 kitty 的所有权限要重新授予一遍。

实现细节：

- 钩子的注册写在 `preFixup` 里。nixpkgs 的 auto-sign hook 在 setup hook 被加载时就已经加进了 `postFixupHooks`，这样写能保证我们的钩子排在它后面。
- 钩子要读取 store 之外的私钥，还要调用 `/usr/bin/codesign` 和 `/usr/libexec/PlistBuddy`，所以**要求 nix 沙盒是关闭的**（`/etc/nix/nix.conf` 里 `sandbox = false`，这也是 darwin 的默认值）。
  用 `__impureHostDeps` 声明这些路径不可行，会报 `not in allowed-impure-host-deps`。
- 选 `rcodesign` 而不是 `/usr/bin/codesign`，是因为后者只能从 keychain 读取签名身份，nixbld 用户没有 keychain；`rcodesign` 可以直接读取 PEM 文件。
- 如果证书文件不存在，求值阶段就会报错，提示先运行 `just kitty-darwin-codesign-init`；如果私钥读不到，构建阶段报错。
- Home Manager 的 `copyApps` 用 `rsync --checksum --copy-unsafe-links --chmod=+w` 复制 App。已验证复制后的 bundle 和 store 里的逐文件一致，签名依然有效。
  它做 App Management 权限检查时写入的 `.DS_Store` 也会被 `--delete` 删掉，不影响签名。

## 部署与首次授权

1. `just kitty-darwin-codesign-init`（只在第一次需要）。
2. **在图形界面的终端里**执行 `just deploy-home`。通过 SSH 执行时，`copyApps` 会因为缺少 App Management 权限而中止。
3. 用 `⌘Q` 完全退出 kitty，再从 `~/Applications/Home Manager Apps/kitty.app` 重新打开。
4. 执行 `printf '\x1b]99;;Hello world\x1b\\'`，**立刻**在右上角的授权弹窗里点「允许」。
5. 其他权限一次性授予：「系统设置 → 隐私与安全性」，在下面几项里点 `+`，选择 `~/Applications/Home Manager Apps/kitty.app`：
   - **完全磁盘访问权限**：覆盖文稿、下载、桌面、iCloud、外接卷、照片图库等所有文件类权限；
   - **辅助功能**、**开发者工具**、**App 管理**、**屏幕与系统录音**，按需添加。

> ⚠️ 通知弹窗大约 2 分钟不处理就会自动消失，这个 Bundle ID 随即卡死（见根因第 2 点）。

以上都只需要做一次。之后 kitty 升级或重新构建，只要私钥和 `bundleId` 不变，这些权限都会保留。

### 为什么不能用配置直接授予权限

在没有 MDM 的个人 Mac 上，这些权限**只能由用户在系统设置里手动授予**：

- TCC.db 受 SIP 保护，sudo 也打不开（`authorization denied`）；
- `tccutil` 只能 `reset`（清除），不能授予；
- 通过 PPPC 描述文件授权，只有 MDM 下发的才会生效，手动安装的会被忽略。

所以能做的就是：**手动授予一次，再让授权不会失效**。证书签名解决的是后半部分。

## 再次失效时怎么办

先确认是哪一层出了问题：

```sh
# 签名是否正确
A=~/Applications/"Home Manager Apps"/kitty.app
codesign --verify --deep --strict -v "$A"
codesign -dv "$A" 2>&1 | grep -E '^Identifier|Info.plist|Sealed'
codesign -dv "$A/Contents/MacOS/.kitty-wrapped" 2>&1 | grep ^Identifier

# 通知守护进程的判定（发一条通知后立即执行）
log show --last 1m --style compact --info \
  --predicate '(process == "usernotificationsd" OR process == "usernoted") AND eventMessage CONTAINS[c] "kovidgoyal"'
```

| 日志 | 含义 | 处理 |
| --- | --- | --- |
| `Entitlement '...bundle-identifiers' required` | 签名标识和 Bundle ID 不一致，overlay 没生效 | 确认 HM 用的是 overlay 后的包（见下方） |
| `Entitlement check success` 之后没有 `Sending request for permission`，kitty 端报 `Notifications are not allowed` | 这个 Bundle ID 已经被 usernoted 记住，卡死了 | 修改 overlay 里的 `bundleId`（例如加后缀 `.2`），重新构建并部署，然后**及时**点允许 |
| 有 `Authorization set for <id> to allow: NO` | 用户在弹窗里点了"不允许" | 到「系统设置 → 通知」里找到 kitty 并打开 |

确认 HM 实际使用的 kitty 包：

```sh
nix eval --raw '.#homeConfigurations."ashenye@mume".config.programs.kitty.package.outPath'
```

### 注意事项

- **不要随便改 `bundleId`，也不要重新生成私钥。** 两者都是 DR 的一部分，改了就等于换了一个新 App，所有权限都要重新授予。只有当前 ID 因为弹窗超时卡死时才换 ID。
- 换 Bundle ID 后，kitty 存在旧 ID 下的 macOS 偏好（例如窗口状态恢复）会从头开始，`kitty.conf` 不受影响。
- 构建时报 `cannot read kitty-darwin-codesign key`：私钥不存在或权限不对（应为 `root:nixbld 0640`），或者 kitty 被分派到了远程构建机上。远程构建机上没有这把私钥，**kitty 必须在本机构建**。

## 其他方案（未采用）

- **Homebrew cask 安装官方签名的 kitty**：官方包有 Developer ID 签名，不会遇到这些问题。可以设置 `programs.kitty.package = null`，这样仍然由 HM 管理 `kitty.conf`。
- **用个人 Apple Development 证书签名**：需要把 keychain 暴露给构建过程，或者每次部署后手动重签，比较麻烦，而且在 TCC 这件事上效果和自签名证书一样。
- **继续用 ad-hoc 签名**：能发通知，但每次重新构建后所有权限都会失效。
- **不走系统通知**：用 `terminal-notifier` 或 `osascript -e 'display notification ...'`，但这样就不能用 OSC 99 了。

## 参考

- NixOS/nixpkgs#545211：wezterm 在 macOS 上因为签名问题无法发通知，是同类问题
- NixOS/nixpkgs#517790：espanso 用稳定的签名标识重新签名的讨论
