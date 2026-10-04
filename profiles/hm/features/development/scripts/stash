#!/usr/bin/env bash
# Dependencies: cat find mktemp mv rm rsync

set -eEuo pipefail
shopt -s failglob
umask 077

declare -r SCRIPT_NAME="${0##*/}"
declare -r EXIT_USAGE=2

TEMP_PATHS=()

cleanup() {
  local temp_path

  for temp_path in "${TEMP_PATHS[@]}"; do
    if [[ -n "${temp_path}" && -e "${temp_path}" ]]; then
      command rm -rf "${temp_path}"
    fi
  done
}

trap cleanup EXIT INT TERM

usage() {
  cat <<EOF
Usage:
  ${SCRIPT_NAME} [--show-rsync-output] <SOURCE>
  ${SCRIPT_NAME} -h | --help

Copy a single rsync source into a local temporary path and print the final path.

If the source resolves to a single file, prints a temp file path.
If the source resolves to a single directory, prints a temp directory path.
If the source resolves to multiple top-level entries (for example a directory
source with a trailing /), prints the temp directory containing those entries.

Options:
  -v, --show-rsync-output  Print the wrapped rsync output instead of hiding it
  -h, --help               Show this help text and exit

Examples:
  ${SCRIPT_NAME} user@example.com:/path/to/file
  ${SCRIPT_NAME} user@example.com:/path/to/directory
  ${SCRIPT_NAME} --show-rsync-output user@example.com:/path/to/directory/
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
    cat
    find
    mktemp
    mv
    rm
    rsync
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

register_temp_path() {
  local temp_path="$1"

  TEMP_PATHS+=("${temp_path}")
}

make_temp_file() {
  local file_tag="$1"
  local base_dir="${TMPDIR:-/tmp}"
  local temp_path

  temp_path="$(mktemp "${base_dir%/}/${file_tag}.XXXXXX")"
  register_temp_path "${temp_path}"
  printf '%s\n' "${temp_path}"
}

make_temp_dir() {
  local dir_tag="$1"
  local base_dir="${TMPDIR:-/tmp}"
  local temp_path

  temp_path="$(mktemp -d "${base_dir%/}/${dir_tag}.XXXXXX")"
  register_temp_path "${temp_path}"
  printf '%s\n' "${temp_path}"
}

count_top_level_entries() {
  local path="$1"
  local count=0

  while IFS= read -r -d '' _; do
    ((count += 1))
  done < <(find "${path}" -mindepth 1 -maxdepth 1 -print0)

  printf '%s\n' "${count}"
}

resolve_single_entry_path() {
  local path="$1"

  find "${path}" -mindepth 1 -maxdepth 1 -print -quit
}

main() {
  local show_rsync_output=false
  local source_path
  local source_copies_contents=false
  local final_path
  local partial_path
  local rsync_log_path
  local entry_count
  local single_entry_path
  local -a rsync_args=(
    -a
    -v
    -z
    -h
    -P
  )

  check_dependencies

  while (($# > 0)); do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      -v|--show-rsync-output)
        show_rsync_output=true
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        usage_error "unknown option: $1"
        ;;
      *)
        break
        ;;
    esac
  done

  if (($# != 1)); then
    usage_error "expected exactly one rsync source path"
  fi

  source_path="$1"
  if [[ "${source_path}" == */ ]]; then
    source_copies_contents=true
  fi
  partial_path="$(make_temp_dir "stash.partial")"
  rsync_log_path="$(make_temp_file "stash.log")"

  if [[ "${show_rsync_output}" == true ]]; then
    command rsync "${rsync_args[@]}" -- "${source_path}" "${partial_path}/"
  else
    if ! command rsync "${rsync_args[@]}" -- "${source_path}" "${partial_path}/" >"${rsync_log_path}" 2>&1; then
      command cat "${rsync_log_path}" >&2
      exit 1
    fi
  fi

  entry_count="$(count_top_level_entries "${partial_path}")"
  if [[ "${source_copies_contents}" == false && "${entry_count}" == "1" ]]; then
    single_entry_path="$(resolve_single_entry_path "${partial_path}")"
    if [[ -d "${single_entry_path}" ]]; then
      final_path="$(make_temp_dir "stash")"
      command rm -rf "${final_path}"
    else
      final_path="$(make_temp_file "stash")"
    fi
    command mv -f "${single_entry_path}" "${final_path}"
    command rm -rf "${partial_path}"
  else
    final_path="$(make_temp_dir "stash")"
    command rm -rf "${final_path}"
    command mv -f "${partial_path}" "${final_path}"
  fi

  command rm -f "${rsync_log_path}"
  trap - EXIT INT TERM
  printf '%s\n' "${final_path}"
}

main "$@"
