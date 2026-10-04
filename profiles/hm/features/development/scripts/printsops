#!/usr/bin/env bash

# A script to print the content of a nix-sops secret.

# Function to display usage information
usage() {
    cat <<EOF
Usage: $(basename "$0") [option...] [KEY]

Options:
  -u, --user UID     Print the specified user's nix-sops secret by UID.
  -s, --system       Print the system-level nix-sops secret.
  -r, --rendered     Look for the rendered version of the secret.
  -h, --help         Display this help and exit.

Description:
  This script prints the content of a nix-sops secret.
  By default, it targets the current user's secrets.
  When KEY is omitted, it lists all available keys (non-directory files)
  under the target secrets directory. The --system and --user options
  are mutually exclusive.

Paths:
  - System secret:           /run/secrets/\$KEY
  - System rendered secret:  /run/secrets/rendered/\$KEY
  - User secret:             /run/user/\$UID/secrets.d/*/\$KEY
  - User rendered secret:    /run/user/\$UID/secrets.d/*/rendered/\$KEY
EOF
    exit 1
}

# Initialize variables
MODE="current" # 'system', 'current', or 'user'
TARGET_UID=""
RENDERED=false
KEY=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--system)
            if [[ "$MODE" == "user" ]]; then
                echo "Error: --system/-s and --user/-u are mutually exclusive." >&2
                exit 1
            fi
            MODE="system"
            shift
            ;;
        -u|--user)
            if [[ "$MODE" == "system" ]]; then
                echo "Error: --system/-s and --user/-u are mutually exclusive." >&2
                exit 1
            fi
            MODE="user"
            if [[ -z "$2" || "$2" =~ ^- ]]; then
                echo "Error: --user/-u requires a UID argument." >&2
                exit 1
            fi
            TARGET_UID="$2"
            shift 2
            ;;        -r|--rendered)
            RENDERED=true
            shift
            ;; 
        -h|--help)
            usage
            ;; 
        -*)
            echo "Error: Unknown option: $1" >&2
            usage
            ;; 
        *)
            # The first non-option argument is the KEY
            if [[ -z "$KEY" ]]; then
                KEY="$1"
            else
                # If KEY is already set, this is an extra argument
                echo "Error: Too many arguments. KEY '$KEY' is already set." >&2
                usage
            fi
            shift
            ;; 
    esac
done

# Determine the final secret path
SECRET_PATH=""

case "$MODE" in
    "system")
        BASE_PATH="/run/secrets"
        if [[ "$RENDERED" == true ]]; then
            SECRET_PATH="$BASE_PATH/rendered/$KEY"
        else
            SECRET_PATH="$BASE_PATH/$KEY"
        fi
        ;; 
    "current")
        UID_TO_USE=$(id -u)
        if [[ -z "$UID_TO_USE" ]]; then
            echo "Error: Could not determine current user's UID." >&2
            exit 1
        fi
        BASE_PATH="/run/user/$UID_TO_USE/secrets.d"
        ;; 
    "user")
        UID_TO_USE="$TARGET_UID"
        BASE_PATH="/run/user/$UID_TO_USE/secrets.d"
        ;; 
esac

# If no KEY is provided, list keys for the chosen mode and exit
if [[ -z "$KEY" ]]; then
    case "$MODE" in
        "system")
            if [[ "$RENDERED" == true ]]; then
                LIST_DIR="/run/secrets/rendered"
            else
                LIST_DIR="/run/secrets"
            fi
            if [[ ! -d "$LIST_DIR" ]]; then
                echo "Error: Directory not found: $LIST_DIR" >&2
                exit 1
            fi
            shopt -s nullglob
            for f in "$LIST_DIR"/*; do
                [[ -f "$f" ]] && basename -- "$f"
            done | sort -u
            shopt -u nullglob
            exit 0
            ;;
        "current"|"user")
            if [[ ! -d "/run/user/$UID_TO_USE" ]]; then
                echo "Error: User with UID $UID_TO_USE does not have a runtime directory, or you lack permissions." >&2
                exit 1
            fi
            shopt -s nullglob
            declare -A SEEN
            if [[ "$RENDERED" == true ]]; then
                for d in "$BASE_PATH"/*; do
                    [[ -d "$d/rendered" ]] || continue
                    for f in "$d"/rendered/*; do
                        [[ -f "$f" ]] || continue
                        name="$(basename -- "$f")"
                        [[ -n "${SEEN[$name]}" ]] && continue
                        SEEN[$name]=1
                        printf "%s\n" "$name"
                    done
                done
            else
                for d in "$BASE_PATH"/*; do
                    [[ -d "$d" ]] || continue
                    for f in "$d"/*; do
                        [[ -f "$f" ]] || continue
                        name="$(basename -- "$f")"
                        [[ -n "${SEEN[$name]}" ]] && continue
                        SEEN[$name]=1
                        printf "%s\n" "$name"
                    done
                done
            fi
            shopt -u nullglob
            exit 0
            ;;
    esac
fi

# For user modes, we need to handle the wildcard path
if [[ "$MODE" == "current" || "$MODE" == "user" ]]; then
    if [[ ! -d "/run/user/$UID_TO_USE" ]]; then
        echo "Error: User with UID $UID_TO_USE does not have a runtime directory, or you lack permissions." >&2
        exit 1
    fi

    PATH_PATTERN=""
    if [[ "$RENDERED" == true ]]; then
        PATH_PATTERN="$BASE_PATH/*/rendered/$KEY"
    else
        PATH_PATTERN="$BASE_PATH/*/$KEY"
    fi

    # Use an array to safely handle glob expansion, even with spaces
    CANDIDATES=( $PATH_PATTERN )

    if [[ ${#CANDIDATES[@]} -eq 0 || ! -f "${CANDIDATES[0]}" ]]; then
        echo "Error: Secret '$KEY' not found for UID $UID_TO_USE at pattern: $PATH_PATTERN" >&2
        exit 1
    elif [[ ${#CANDIDATES[@]} -gt 1 ]]; then
        echo "Error: Ambiguous secret. Multiple matches found for UID $UID_TO_USE:" >&2
        printf "  %s\n" "${CANDIDATES[@]}"
        exit 1
    fi
    SECRET_PATH="${CANDIDATES[0]}"
fi


# Check if the final path exists and is a regular file
if [[ ! -f "$SECRET_PATH" ]]; then
    echo "Error: Secret file not found or is not a regular file: $SECRET_PATH" >&2
    exit 1
fi

# Print the secret content
cat "$SECRET_PATH"
