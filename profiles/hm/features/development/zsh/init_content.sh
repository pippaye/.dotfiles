function mkcd {
  mkdir -p "$1" && cd "$1" || exit
}

function ns {
  nix search nixpkgs $@
}

function nd {
  nix develop ${1:=.}
}

function nsh {
  local args=()
  for arg in $@; do
  args+=("nixpkgs#$arg");
  done
  nix shell ${args[@]};
}

function nr {
  nix run nixpkgs#$@
}

function np {
  nix build --print-out-paths --no-link nixpkgs#$1
}

# nbu <format> <drivation>
# <format> ::= arx | rpm | deb | dockerimage | appimage
function nbu {
  local format="$1"
  local derivation="$2"
  if [ -z "$format" ]; then
    echo "Error: <format> is required"
    echo "Usage: nbu <format> <derivation>"
    return 1
  fi
  if [ -z "$derivation" ]; then
    echo "Error: <derivation> is required"
    echo "Usage: nbu <format> <derivation>"
    return 1
  fi
  local bundler=""
  case "$format" in
    arx) bundler="github:Nixos/bundlers#toArx";;
    rpm) bundler="github:Nixos/bundlers#toRPM";;
    deb) bundler="github:Nixos/bundlers#toDEB";;
    dockerimage) bundler="github:Nixos/bundlers#toDockerImage";;
    appimage) bundler="github:ralismark/nix-appimage";;
    *) echo "Unknown format: $format"; return 1;;
  esac
  nix bundle --bundler "$bundler" "$derivation"
}

function append_path {
  for dir in "$@"; do
    if [ -d "$dir" ] && [[ ":$PATH:" != *":$dir:"* ]]; then
      export PATH="$PATH:$dir"
    fi
  done
}

function cwt {
  mkdir -p .codex/worktrees
  git worktree add .codex/worktrees/$1 -b $1
}

function xs {
  if [[ $# -lt 1 ]]; then
    echo "Usage: pssh proxy-ip:proxy-port [ssh args...]"
    return 1
  fi
  local proxy="$1"
  shift
  ssh -o "ProxyCommand=nc -x ${proxy} %h %p" "$@"
}

function kxs {
  if [[ $# -lt 1 ]]; then
    echo "Usage: pssh proxy-ip:proxy-port [ssh args...]"
    return 1
  fi
  local proxy="$1"
  shift
  kitten ssh -o "ProxyCommand=nc -x ${proxy} %h %p" "$@"
}

function up {
  local d=""
  local limit=${1:-1}
  for ((i=0; i<limit; i++)); do
    d+="../"
  done
  cd "$d"
}

function wttr {
  CITY=$(curl -s "https://r.inews.qq.com/api/ip2city" | jq '.city' -r)
  curl -s "wttr.in/${CITY}?lang=zh-cn" | bat
}

function pj_new {
  mkdir ~/repo/$1 && cd ~/repo/$1
}

function iv {
  fd --type=file | fzf --multi --preview 'bat --color=always --style=numbers --line-range=:100 {}' | xargs vim
}

function gtc {
    # 检查是否提供了仓库地址
    if [ -z "$1" ]; then
        echo "Usage: git_temp_clone <repository-url> [additional-git-clone-options]"
        return 1
    fi

    local repo_url="$1"
    shift # 移除第一个参数，方便将后续的参数传递给 git clone

    # 创建临时目录（兼顾 macOS 和 Linux 的 mktemp 命令差异）
    local temp_dir
    temp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'git-tmp')

    if [ -z "$temp_dir" ] || [ ! -d "$temp_dir" ]; then
        echo "Error: Failed to create temporary directory."
        return 1
    fi

    echo "Created temporary directory: $temp_dir"

    # 执行克隆操作，将仓库直接克隆到该临时目录下
    if git clone "$repo_url" "$temp_dir" "$@"; then
        # 克隆成功后进入该目录
        cd "$temp_dir" || return 1
        echo "Successfully cloned and entered: $temp_dir"
    else
        # 如果克隆失败，清理刚刚创建的临时目录
        echo "Error: Git clone failed. Cleaning up temporary directory..."
        rm -rf "$temp_dir"
        return 1
    fi
}

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
