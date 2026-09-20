#!/usr/bin/env bash
set -euo pipefail

log() {
  if [[ ${ANYCOPY_DEBUG:-0} == 1 ]]; then
    printf 'anycopy: %s\n' "$*" >&2
  fi
}

die() {
  printf 'anycopy: %s\n' "$*" >&2
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

# stdin -> OSC 52 -> 当前终端的系统剪贴板
osc52() {
  have base64 || die "OSC 52 requires 'base64'"

  # 普通 `cmd | anycopy` 时 stdout 是 tty，直接写 /dev/tty。
  # ssh host 'cmd | anycopy' 没有分配远端 PTY 时，
  # stdout 仍然是通向 SSH 客户端的正确通道。
  if [[ -t 1 && -w /dev/tty ]]; then
    exec 3>/dev/tty
  else
    exec 3>&1
  fi

  {
    printf '\033]52;c;'
    base64 | tr -d '\r\n'
    printf '\033\\'
  } >&3

  exec 3>&-
}

tmux_has_load_buffer_w() {
  tmux list-commands 2>/dev/null |
    awk '$1 == "load-buffer" && /-w/ {
      found=1
    }
    END {
      exit !found
    }'
}

copy_tmux() {
  # tmux >= 3.2
  #
  # -w 会让 tmux 主动把 buffer 发送到外层终端的 clipboard。
  if tmux_has_load_buffer_w; then
    log "backend=tmux (load-buffer -w)"
    exec tmux load-buffer -w -
  fi

  # 老 tmux fallback。
  # 需要 set-clipboard=on 才能允许 pane 内程序发送 OSC 52。
  log "backend=tmux-old -> OSC52"
  osc52
}

copy_auto() {
  #
  # 1. tmux
  #
  # 优先级最高，因为：
  #
  #   SSH -> tmux
  #   Zellij -> tmux
  #   tmux -> Zellij
  #
  # 只要 TMUX 还在环境变量里，就可以直接让 tmux server
  # 把内容送到它的 client clipboard。
  #
  if [[ -n ${TMUX:-} ]] && have tmux; then
    copy_tmux
    return
  fi

  #
  # 2. Zellij
  #
  # Zellij 原生支持 pane 内程序发出的 OSC 52。
  #
  if [[ -n ${ZELLIJ:-} || -n ${ZELLIJ_SESSION_NAME:-} ]]; then
    log "backend=zellij -> OSC52"
    osc52
    return
  fi

  #
  # 3. SSH
  #
  # 这里绝对不要优先调用远端 wl-copy / pbcopy。
  # 我们想操作的是 SSH 客户端机器的 clipboard。
  #
  if [[ -n ${SSH_TTY:-} ||
        -n ${SSH_CONNECTION:-} ||
        -n ${SSH_CLIENT:-} ]]; then
    log "backend=ssh -> OSC52"
    osc52
    return
  fi

  #
  # 4. 本机 macOS
  #
  if [[ $(uname -s 2>/dev/null || true) == Darwin ]] &&
     have pbcopy; then
    log "backend=macOS (pbcopy)"
    exec pbcopy
  fi

  #
  # 5. 本机 Wayland
  #
  if [[ -n ${WAYLAND_DISPLAY:-} ||
        ${XDG_SESSION_TYPE:-} == wayland ]] &&
     have wl-copy; then
    log "backend=wayland (wl-copy)"
    exec wl-copy
  fi

  #
  # 6. 顺手兼容 X11
  #
  if [[ -n ${DISPLAY:-} ]] && have xclip; then
    log "backend=x11 (xclip)"
    exec xclip -selection clipboard
  fi

  if [[ -n ${DISPLAY:-} ]] && have xsel; then
    log "backend=x11 (xsel)"
    exec xsel --clipboard --input
  fi

  #
  # 7. 最后的 fallback
  #
  if [[ -t 1 ]]; then
    log "backend=fallback -> OSC52"
    osc52
    return
  fi

  die "no clipboard backend found"
}

#
# 允许手动覆盖探测结果：
#
#   ANYCOPY_BACKEND=osc52
#   ANYCOPY_BACKEND=tmux
#   ANYCOPY_BACKEND=pbcopy
#   ANYCOPY_BACKEND=wl-copy
#
case ${ANYCOPY_BACKEND:-auto} in
  auto)
    copy_auto
    ;;

  tmux)
    have tmux || die "tmux not found"
    copy_tmux
    ;;

  zellij|ssh|osc52)
    osc52
    ;;

  macos|pbcopy)
    have pbcopy || die "pbcopy not found"
    exec pbcopy
    ;;

  wayland|wl-copy)
    have wl-copy || die "wl-copy not found"
    exec wl-copy
    ;;

  xclip)
    have xclip || die "xclip not found"
    exec xclip -selection clipboard
    ;;

  xsel)
    have xsel || die "xsel not found"
    exec xsel --clipboard --input
    ;;

  *)
    die "unknown ANYCOPY_BACKEND=${ANYCOPY_BACKEND}"
    ;;
esac
