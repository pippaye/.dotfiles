#!/usr/bin/env bash
set -euo pipefail

CONFIG="${CHEATSHEET_CONFIG:-$HOME/.config/cheatsheet.json}"

die() {
  printf 'cheatsheet: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  cheatsheet
  cheatsheet <name>
  cheatsheet --list
  cheatsheet --path <name>
  cheatsheet --help

Browse personal Markdown cheatsheets.

Config:
  ~/.config/cheatsheet.json

Example config:
  {
    "root": "~/notes/cheatsheets"
  }
EOF
}

find_command() {
  local cmd
  for cmd in "$@"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      command -v "$cmd"
      return 0
    fi
  done
  return 1
}

expand_tilde() {
  case "$1" in
    "~") printf '%s\n' "$HOME" ;;
    "~/"*) printf '%s/%s\n' "$HOME" "${1#~/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

load_root() {
  local jq_cmd root

  jq_cmd="$(find_command jq)" || die "missing dependency: jq"
  [[ -f "$CONFIG" ]] || die "missing config: $CONFIG"

  root="$("$jq_cmd" -er '.root // empty | select(type == "string" and length > 0)' "$CONFIG" 2>/dev/null)" \
    || die "config must contain a non-empty string field: root"

  root="$(expand_tilde "$root")"
  [[ -d "$root" ]] || die "configured root is not a directory: $root"

  (cd "$root" && pwd -P)
}

fd_cmd() {
  find_command fd fdfind || die "missing dependency: fd or fdfind"
}

fzf_cmd() {
  find_command fzf || die "missing dependency: fzf"
}

bat_cmd() {
  find_command bat batcat || die "missing dependency: bat or batcat"
}

list_files() {
  local root="$1"
  local fd="$2"

  (cd "$root" && "$fd" --type f --extension md . | sed 's#^\./##' | LC_ALL=C sort)
}

select_file() {
  local root="$1"
  local fd="$2"
  local fzf="$3"
  local prompt="${4:-cheatsheet> }"
  local selection

  selection="$(list_files "$root" "$fd" | "$fzf" --prompt "$prompt")" || return 1
  [[ -n "$selection" ]] || return 1
  printf '%s\n' "$selection"
}

find_by_name() {
  local root="$1"
  local fd="$2"
  local name="$3"

  (cd "$root" && "$fd" --type f --extension md --glob "$name.md" . | sed 's#^\./##' | LC_ALL=C sort)
}

strip_frontmatter() {
  local file="$1"

  awk '
    NR == 1 && $0 == "---" {
      in_frontmatter = 1
      next
    }
    in_frontmatter && $0 == "---" {
      in_frontmatter = 0
      next
    }
    !in_frontmatter {
      print
    }
  ' "$file"
}

show_file() {
  local root="$1"
  local rel="$2"
  local bat="$3"
  local file="$root/$rel"

  [[ -f "$file" ]] || die "not a file: $file"
  strip_frontmatter "$file" | "$bat" --language markdown --paging always --style plain
}

absolute_path() {
  local root="$1"
  local rel="$2"

  printf '%s/%s\n' "$root" "$rel"
}

choose_match() {
  local matches="$1"
  local prompt="$2"
  local fzf
  local count

  count="$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l | tr -d ' ')"
  case "$count" in
    0) return 1 ;;
    1) printf '%s\n' "$matches" ;;
    *)
      fzf="$(fzf_cmd)"
      printf '%s\n' "$matches" | "$fzf" --prompt "$prompt"
      ;;
  esac
}

main() {
  local root fd fzf bat matches rel

  case "${1:-}" in
    -h|--help)
      usage
      return 0
      ;;
  esac

  root="$(load_root)"
  fd="$(fd_cmd)"

  case "$#" in
    0)
      fzf="$(fzf_cmd)"
      bat="$(bat_cmd)"
      rel="$(select_file "$root" "$fd" "$fzf")" || return 1
      show_file "$root" "$rel" "$bat"
      ;;
    1)
      case "$1" in
        --list)
          list_files "$root" "$fd"
          ;;
        --path)
          die "--path requires a name"
          ;;
        --*)
          usage >&2
          return 2
          ;;
        *)
          matches="$(find_by_name "$root" "$fd" "$1")"
          rel="$(choose_match "$matches" "matches> ")" || die "no cheatsheet found: $1"
          bat="$(bat_cmd)"
          show_file "$root" "$rel" "$bat"
          ;;
      esac
      ;;
    2)
      case "$1" in
        --path)
          matches="$(find_by_name "$root" "$fd" "$2")"
          rel="$(choose_match "$matches" "matches> ")" || die "no cheatsheet found: $2"
          absolute_path "$root" "$rel"
          ;;
        *)
          usage >&2
          return 2
          ;;
      esac
      ;;
    *)
      usage >&2
      return 2
      ;;
  esac
}

main "$@"
