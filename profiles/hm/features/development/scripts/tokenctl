#!/usr/bin/env bash
# Dependencies: find

set -eEuo pipefail
shopt -s failglob
umask 077

declare -r SCRIPT_NAME="${0##*/}"
declare -r DEFAULT_STATE_DIR="${HOME}/.local/state"
declare -r TOKENS_SUBDIR="tokens"
declare -r EXIT_USAGE=2
declare -r EXIT_NOT_FOUND=3
declare -r EXIT_EXPIRED=4

TEMP_PATHS=()

cleanup() {
  local temp_path

  for temp_path in "${TEMP_PATHS[@]}"; do
    if [[ -n "${temp_path}" && -e "${temp_path}" ]]; then
      command rm -f "${temp_path}"
    fi
  done
}

trap cleanup EXIT INT TERM

usage() {
  cat <<EOF
Usage:
  ${SCRIPT_NAME} add <TOKEN_NAME> [<TOKEN_VAL>] [--ttl <time>]
  ${SCRIPT_NAME} cat <TOKEN_NAME>
  ${SCRIPT_NAME} ls
  ${SCRIPT_NAME} path <TOKEN_NAME>
  ${SCRIPT_NAME} copy <TOKEN_NAME>
  ${SCRIPT_NAME} del <TOKEN_NAME>
  ${SCRIPT_NAME} <TOKEN_NAME>
  ${SCRIPT_NAME} -h | --help

Store tokens under:
  \${XDG_STATE_DIR:-\$HOME/.local/state}/tokens

Commands:
  add              Add or replace a token. If TOKEN_VAL is omitted, read from stdin or prompt.
  cat              Print a token to stdout. Expired tokens are deleted automatically.
  ls               List stored token names.
  path             Print the filesystem path for a token file.
  copy             Copy a token to the system clipboard.
  del              Delete a token and any TTL metadata.

Options:
  --ttl <time>     Set a relative TTL using one of: Ns, Nm, Nh, Nd
  -h, --help       Show this help text and exit

Examples:
  ${SCRIPT_NAME} add api_key secret123
  printf '%s' 'secret123' | ${SCRIPT_NAME} add api_key
  ${SCRIPT_NAME} add api_key secret123 --ttl 12h
  ${SCRIPT_NAME} ls
  ${SCRIPT_NAME} cat api_key
  ${SCRIPT_NAME} api_key
  ${SCRIPT_NAME} path api_key
  ${SCRIPT_NAME} copy api_key
  ${SCRIPT_NAME} del api_key
EOF
}

error() {
  local message="$1"

  printf '%s: %s\n' "${SCRIPT_NAME}" "${message}" >&2
}

usage_error() {
  local message="$1"

  error "${message}"
  printf '\n' >&2
  usage >&2
  exit "${EXIT_USAGE}"
}

check_dependencies() {
  local required_commands=(
    chmod
    cat
    date
    find
    mkdir
    mktemp
    mv
    rm
  )
  local missing_commands=()
  local command_name

  for command_name in "${required_commands[@]}"; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
      missing_commands+=("${command_name}")
    fi
  done

  if ((${#missing_commands[@]} > 0)); then
    error "missing required commands: ${missing_commands[*]}"
    exit 1
  fi
}

get_state_dir() {
  local state_dir="${XDG_STATE_DIR:-${DEFAULT_STATE_DIR}}"

  printf '%s\n' "${state_dir}"
}

get_tokens_dir() {
  local tokens_dir

  tokens_dir="$(get_state_dir)/${TOKENS_SUBDIR}"
  printf '%s\n' "${tokens_dir}"
}

validate_token_name() {
  local token_name="$1"

  if [[ ! "${token_name}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    return 1
  fi

  if [[ "${token_name}" == *..* ]]; then
    return 1
  fi

  return 0
}

token_path() {
  local token_name="$1"

  printf '%s/%s\n' "$(get_tokens_dir)" "${token_name}"
}

meta_path() {
  local token_name="$1"

  printf '%s/%s.meta\n' "$(get_tokens_dir)" "${token_name}"
}

register_temp_path() {
  local temp_path="$1"

  TEMP_PATHS+=("${temp_path}")
}

make_temp_file() {
  local dir_path="$1"
  local file_tag="$2"
  local temp_path

  temp_path="$(mktemp "${dir_path}/.tmp.${file_tag}.XXXXXX")"
  register_temp_path "${temp_path}"
  printf '%s\n' "${temp_path}"
}

parse_ttl_to_seconds() {
  local ttl_input="$1"
  local quantity_text
  local quantity
  local unit

  if [[ ! "${ttl_input}" =~ ^([0-9]+)([smhd])$ ]]; then
    return 1
  fi

  quantity_text="${BASH_REMATCH[1]}"
  unit="${BASH_REMATCH[2]}"
  quantity=$((10#${quantity_text}))

  case "${unit}" in
    s)
      printf '%s\n' "${quantity}"
      ;;
    m)
      printf '%s\n' "$((quantity * 60))"
      ;;
    h)
      printf '%s\n' "$((quantity * 3600))"
      ;;
    d)
      printf '%s\n' "$((quantity * 86400))"
      ;;
    *)
      return 1
      ;;
  esac
}

require_valid_token_name() {
  local token_name="$1"

  if ! validate_token_name "${token_name}"; then
    usage_error "invalid TOKEN_NAME: ${token_name}"
  fi
}

require_token_available() {
  local token_name="$1"
  local token_file
  local token_meta_file
  local expires_at
  local now_epoch

  token_file="$(token_path "${token_name}")"
  token_meta_file="$(meta_path "${token_name}")"

  if [[ ! -f "${token_file}" ]]; then
    error "token not found: ${token_name}"
    exit "${EXIT_NOT_FOUND}"
  fi

  if [[ -f "${token_meta_file}" ]]; then
    expires_at="$(<"${token_meta_file}")"

    if [[ ! "${expires_at}" =~ ^[0-9]+$ ]]; then
      error "invalid TTL metadata for token: ${token_name}"
      exit 1
    fi

    now_epoch="$(command date +%s)"
    if ((10#${now_epoch} >= 10#${expires_at})); then
      command rm -f "${token_file}" "${token_meta_file}"
      error "token has expired and was deleted: ${token_name}"
      exit "${EXIT_EXPIRED}"
    fi
  fi
}

list_clipboard_backends() {
  local has_wl_copy=0
  local has_xclip=0
  local has_xsel=0

  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s\n' "pbcopy"
  fi

  if command -v wl-copy >/dev/null 2>&1; then
    has_wl_copy=1
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
      printf '%s\n' "wl-copy"
    fi
  fi

  if command -v xclip >/dev/null 2>&1; then
    has_xclip=1
    if [[ -n "${DISPLAY:-}" ]]; then
      printf '%s\n' "xclip"
    fi
  fi

  if command -v xsel >/dev/null 2>&1; then
    has_xsel=1
    if [[ -n "${DISPLAY:-}" ]]; then
      printf '%s\n' "xsel"
    fi
  fi

  if ((has_wl_copy == 1)) && [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    printf '%s\n' "wl-copy"
  fi

  if ((has_xclip == 1)) && [[ -z "${DISPLAY:-}" ]]; then
    printf '%s\n' "xclip"
  fi

  if ((has_xsel == 1)) && [[ -z "${DISPLAY:-}" ]]; then
    printf '%s\n' "xsel"
  fi
}

copy_with_backend() {
  local clipboard_backend="$1"
  local source_file="$2"

  case "${clipboard_backend}" in
    pbcopy)
      command pbcopy <"${source_file}"
      ;;
    wl-copy)
      command wl-copy <"${source_file}"
      ;;
    xclip)
      command xclip -selection clipboard -in <"${source_file}"
      ;;
    xsel)
      command xsel --clipboard --input <"${source_file}"
      ;;
    *)
      return 1
      ;;
  esac

  return 0
}

copy_file_to_clipboard() {
  local source_file="$1"
  local backend_error_file
  local backend_error_message=""
  local clipboard_backend
  local clipboard_backends=()

  while IFS= read -r clipboard_backend; do
    clipboard_backends+=("${clipboard_backend}")
  done < <(list_clipboard_backends)

  if ((${#clipboard_backends[@]} == 0)); then
    error "no supported clipboard command found (tried: pbcopy, wl-copy, xclip, xsel)"
    exit 1
  fi

  backend_error_file="$(mktemp)"
  register_temp_path "${backend_error_file}"

  for clipboard_backend in "${clipboard_backends[@]}"; do
    : >"${backend_error_file}"

    if copy_with_backend "${clipboard_backend}" "${source_file}" 2>"${backend_error_file}"; then
      return 0
    fi
  done

  if [[ -s "${backend_error_file}" ]]; then
    backend_error_message="$(tr '\n' ' ' <"${backend_error_file}")"
  fi

  error "failed to copy token using available clipboard backends: ${clipboard_backends[*]}"
  if [[ -n "${backend_error_message}" ]]; then
    error "${backend_error_message}"
  fi

  exit 1
}

read_token_from_tty() {
  local token_name="$1"
  local token_value=""

  printf 'Enter token value for %s: ' "${token_name}" >&2
  if ! IFS= read -r -s token_value; then
    printf '\n' >&2
    error "failed to read TOKEN_VAL from terminal"
    exit 1
  fi

  printf '\n' >&2
  printf '%s' "${token_value}"
}

handle_add() {
  local token_name=""
  local token_value=""
  local ttl_input=""
  local ttl_seconds=""
  local token_file
  local token_meta_file
  local tokens_dir
  local token_temp_file
  local meta_temp_file
  local now_epoch
  local expires_at
  local has_token_value=0
  local argument

  while (($# > 0)); do
    argument="$1"

    case "${argument}" in
      -h|--help)
        usage
        exit 0
        ;;
      --ttl)
        shift
        if (($# == 0)); then
          usage_error "missing value for --ttl"
        fi
        if [[ -n "${ttl_input}" ]]; then
          usage_error "duplicate --ttl option"
        fi
        ttl_input="$1"
        ;;
      --ttl=*)
        if [[ -n "${ttl_input}" ]]; then
          usage_error "duplicate --ttl option"
        fi
        ttl_input="${argument#--ttl=}"
        if [[ -z "${ttl_input}" ]]; then
          usage_error "missing value for --ttl"
        fi
        ;;
      --*)
        usage_error "unknown option for add: ${argument}"
        ;;
      *)
        if [[ -z "${token_name}" ]]; then
          token_name="${argument}"
        elif ((has_token_value == 0)); then
          token_value="${argument}"
          has_token_value=1
        else
          usage_error "unexpected argument for add: ${argument}"
        fi
        ;;
    esac

    shift
  done

  if [[ -z "${token_name}" ]]; then
    usage_error "add requires TOKEN_NAME"
  fi

  require_valid_token_name "${token_name}"

  if [[ -n "${ttl_input}" ]]; then
    if ! ttl_seconds="$(parse_ttl_to_seconds "${ttl_input}")"; then
      usage_error "invalid --ttl value: ${ttl_input}"
    fi
  fi

  tokens_dir="$(get_tokens_dir)"
  token_file="$(token_path "${token_name}")"
  token_meta_file="$(meta_path "${token_name}")"

  command mkdir -p "${tokens_dir}"

  token_temp_file="$(make_temp_file "${tokens_dir}" "${token_name}")"

  if ((has_token_value == 1)); then
    printf '%s' "${token_value}" >"${token_temp_file}"
  else
    if [[ -t 0 ]]; then
      token_value="$(read_token_from_tty "${token_name}")"
      printf '%s' "${token_value}" >"${token_temp_file}"
    else
      command cat >"${token_temp_file}"
    fi
  fi

  command chmod 400 "${token_temp_file}"
  command mv "${token_temp_file}" "${token_file}"

  if [[ -n "${ttl_seconds}" ]]; then
    meta_temp_file="$(make_temp_file "${tokens_dir}" "${token_name}.meta")"
    now_epoch="$(command date +%s)"
    expires_at=$((10#${now_epoch} + ttl_seconds))
    printf '%s\n' "${expires_at}" >"${meta_temp_file}"
    command chmod 400 "${meta_temp_file}"
    command mv "${meta_temp_file}" "${token_meta_file}"
  else
    command rm -f "${token_meta_file}"
  fi
}

handle_cat() {
  local token_name
  local token_file

  if (($# == 1)) && [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
  fi

  if (($# != 1)); then
    usage_error "cat expects exactly one TOKEN_NAME"
  fi

  token_name="$1"
  require_valid_token_name "${token_name}"
  require_token_available "${token_name}"

  token_file="$(token_path "${token_name}")"

  command cat "${token_file}"
}

handle_ls() {
  local tokens_dir
  local token_file

  if (($# == 1)) && [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
  fi

  if (($# != 0)); then
    usage_error "ls does not accept positional arguments"
  fi

  tokens_dir="$(get_tokens_dir)"

  if [[ ! -d "${tokens_dir}" ]]; then
    return 0
  fi

  while IFS= read -r token_file; do
    printf '%s\n' "${token_file##*/}"
  done < <(
    command find "${tokens_dir}" \
      -mindepth 1 \
      -maxdepth 1 \
      -type f \
      ! -name '*.meta' \
      ! -name '.tmp.*' \
      -print
  )
}

handle_path() {
  local token_name

  if (($# == 1)) && [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
  fi

  if (($# != 1)); then
    usage_error "path expects exactly one TOKEN_NAME"
  fi

  token_name="$1"
  require_valid_token_name "${token_name}"

  token_path "${token_name}"
}

handle_copy() {
  local token_name
  local token_file

  if (($# == 1)) && [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
  fi

  if (($# != 1)); then
    usage_error "copy expects exactly one TOKEN_NAME"
  fi

  token_name="$1"
  require_valid_token_name "${token_name}"
  require_token_available "${token_name}"

  token_file="$(token_path "${token_name}")"
  copy_file_to_clipboard "${token_file}"
}

handle_del() {
  local token_name
  local token_file
  local token_meta_file

  if (($# == 1)) && [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
  fi

  if (($# != 1)); then
    usage_error "del expects exactly one TOKEN_NAME"
  fi

  token_name="$1"
  require_valid_token_name "${token_name}"

  token_file="$(token_path "${token_name}")"
  token_meta_file="$(meta_path "${token_name}")"

  if [[ ! -e "${token_file}" && ! -e "${token_meta_file}" ]]; then
    error "token not found: ${token_name}"
    exit "${EXIT_NOT_FOUND}"
  fi

  command rm -f "${token_file}" "${token_meta_file}"
}

main() {
  local subcommand

  check_dependencies

  if (($# == 0)); then
    usage_error "missing command"
  fi

  subcommand="$1"
  shift

  case "${subcommand}" in
    -h|--help)
      usage
      ;;
    add)
      handle_add "$@"
      ;;
    cat)
      handle_cat "$@"
      ;;
    ls)
      handle_ls "$@"
      ;;
    path)
      handle_path "$@"
      ;;
    copy)
      handle_copy "$@"
      ;;
    del)
      handle_del "$@"
      ;;
    *)
      handle_cat "${subcommand}" "$@"
      ;;
  esac
}

main "$@"
