#!/usr/bin/env bash
#
# check-libs.sh: Scans a directory for executables and shared libraries (.so)
#                to identify any missing dynamically linked libraries.
#
# Author: Gemini
# Version: 1.0.0

# Dependencies: find, file, grep, ldd (on Linux), otool (on macOS)

# =============================================================================
# Script Setup and Robustness
# =============================================================================

# Exit immediately if a command exits with a non-zero status.
# -e: Exit on error.
# -E: ERR trap is inherited by shell functions, command substitutions, etc.
# -u: Treat unset variables as an error.
# -o pipefail: The return value of a pipeline is the status of the last
#              command to exit with a non-zero status, or zero if no command
#              exited with a non-zero status.
set -eEuo pipefail

# Treat glob patterns that don't match any files as an error.
shopt -s failglob

# =============================================================================
# Global Constants and Variables
# =============================================================================

# Use 'declare' for read-only variables to make intent clear.
declare -r SCRIPT_NAME="$(basename "$0")"

# =============================================================================
# Functions
# =============================================================================

# ---
# Gracefully handles script termination, cleaning up any temporary resources.
# This script doesn't create temp files, but this is a best practice.
# ---
cleanup() {
    # The colon is a no-op, serving as a placeholder.
    :
}

# ---
# Displays help and usage information for the script.
# ---
usage() {
  # Using a HEREDOC for clean, multi-line output.
  cat <<EOF
Usage: ${SCRIPT_NAME} [-h|--help] [DIRECTORY]

Scans a target directory for ELF/Mach-O executables and shared libraries to
find and report any missing dynamic library dependencies.

Arguments:
  DIRECTORY     The directory to scan. Defaults to the current working
                directory (pwd) if not provided.

Options:
  -h, --help    Display this help message and exit.
EOF
}

# ---
# Verifies that all required external commands are available in the PATH.
# Tailors the dependency check based on the detected operating system.
# ---
check_dependencies() {
    local os_type
    os_type="$(uname -s)"
    local -a deps # Declare an array for dependencies

    case "${os_type}" in
        Linux*)
            deps=("find" "file" "grep" "ldd")
            ;;
        Darwin*)
            deps=("find" "file" "grep" "otool")
            ;;
        *)
            echo "Error: Unsupported OS '${os_type}'." >&2
            echo "This script only supports Linux and macOS (Darwin)." >&2
            exit 1
            ;;
    esac

    local missing_deps=0
    for cmd in "${deps[@]}"; do
        if ! command -v "${cmd}" &>/dev/null; then
            echo "Error: Required dependency '${cmd}' is not installed or not in PATH." >&2
            missing_deps=$((missing_deps + 1))
        fi
    done

    if [[ ${missing_deps} -gt 0 ]]; then
        exit 1
    fi
}

# ---
# The main function orchestrating the script's execution.
# ---
main() {
    # Check dependencies before proceeding.
    check_dependencies

    # Default scan directory to current working directory.
    local target_dir="."

    # --- Parameter Parsing ---
    if [[ $# -gt 1 ]]; then
        echo "Error: Too many arguments provided." >&2
        usage >&2
        exit 1
    fi

    if [[ $# -eq 1 ]]; then
        case "$1" in
            -h | --help)
                usage
                exit 0
                ;;
            *)
                target_dir="$1"
                ;;
        esac
    fi

    if [[ ! -d "${target_dir}" ]]; then
        echo "Error: Directory '${target_dir}' does not exist." >&2
        exit 1
    fi

    # The final, validated target directory is made read-only.
    declare -r final_target_dir="${target_dir}"
    declare -r os_type="$(uname -s)"
    local found_missing=false # Flag to track if any issues were found.

    echo "🚀 Scanning for missing libraries in '${final_target_dir}'..."

    # The 'find' command is compatible across both platforms.
    # It searches for files that are either named *.so or have execute permissions.
    find "${final_target_dir}" -type f \( -name "*.so" -o -perm /u+x \) | while read -r file; do
        # This check ensures we only process actual binary files, skipping scripts.
        # It's adapted for both Linux (ELF) and macOS (Mach-O).
        if ! file "${file}" | grep -qE 'ELF.*(executable|shared object)|Mach-O.*(executable|dynamically linked shared library)'; then
            continue
        fi

        local output=""
        # --- Platform-Specific Logic ---
        if [[ "${os_type}" == "Linux"* ]]; then
            # On Linux, 'ldd' explicitly states when a library is "not found".
            # We add '|| true' so that if 'grep' finds nothing (and exits with 1),
            # the 'set -e' option doesn't prematurely terminate the script.
            output="$(ldd "${file}" 2>&1 | grep 'not found' || true)"
        elif [[ "${os_type}" == "Darwin"* ]]; then
            # On macOS, 'otool -L' lists linked libraries. A missing library doesn't
            # throw an explicit "not found" error. Instead, we must check if each
            # listed library path actually exists on the filesystem.
            # We use 'tail' to skip the first line, which is the file itself.
            output="$(otool -L "${file}" | tail -n +2 | while read -r line; do
                local lib_path
                # awk extracts the library path, which is the first field.
                lib_path="$(echo "${line}" | awk '{print $1}')"
                # Check if the path is non-empty and if the file does not exist.
                if [[ -n "${lib_path}" && ! -e "${lib_path}" ]]; then
                    echo "  => ${lib_path} (not found)"
                fi
            done)"
        fi

        if [[ -n "${output}" ]]; then
            if ! ${found_missing}; then
                echo # Add a newline for better formatting before the first error report.
                found_missing=true
            fi
            echo "----------------------------------------"
            echo "🚨 File with missing libraries: ${file}"
            echo "${output}"
        fi
    done

    echo # Add a final newline for clean exit.
    if ! ${found_missing}; then
        echo "✅ Scan complete. No missing libraries found."
    else
        echo "----------------------------------------"
        echo "⚠️ Scan complete. Found files with issues."
    fi
}

# =============================================================================
# Script Entry Point
# =============================================================================

# Register the cleanup function to be called on script exit.
trap cleanup EXIT INT TERM

# Call the main function, passing all script arguments to it.
main "$@"