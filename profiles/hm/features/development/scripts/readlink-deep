#!/usr/bin/env bash

# Default values
verbose=false
max_depth=-1
exact_depth=-1
symlink=""

# --- Usage function ---
usage() {
    cat <<EOF
Usage: readlink-deep [options ...] <symlink>
Recursively resolve a symbolic link with cycle detection.

Options:
  -v, --verbose      Print the resolution chain (e.g., start -> via -> dest).
  -m, --max-depth <d>  Specify the maximum resolution depth.
  -d, --depth <d>      Resolve exactly <d> times. Fails if resolution ends sooner.
                     (Cannot be used with -v or -m).
  -h, --help         Display this help message.
EOF
    exit 1
}

# --- Argument parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) verbose=true; shift ;;
        -m|--max-depth)
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "Error: --max-depth requires a non-negative integer." >&2
                exit 1
            fi
            max_depth=$2
            shift 2
            ;;
        -d|--depth)
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "Error: --depth requires a non-negative integer." >&2
                exit 1
            fi
            exact_depth=$2
            shift 2
            ;;
        -h|--help) usage ;;
        -*) echo "Unknown option: $1" >&2; usage ;;
        *)
            if [ -z "$symlink" ]; then
                symlink=$1
            else
                echo "Error: Only one symlink path can be provided." >&2
                usage
            fi
            shift
            ;;
    esac
done

# --- Validate arguments ---
if [ -z "$symlink" ]; then
    echo "Error: Missing symlink argument." >&2
    usage
fi

if [ "$exact_depth" -ne -1 ] && ($verbose || [ "$max_depth" -ne -1 ]); then
    echo "Error: --depth (-d) cannot be used with --verbose (-v) or --max-depth (-m)." >&2
    usage
fi

if [ ! -L "$symlink" ]; then
    if [ -e "$symlink" ]; then
        echo "Error: '$symlink' exists but is not a symbolic link." >&2
    else
        echo "Error: '$symlink' does not exist or is a broken link." >&2
    fi
    exit 1
fi

# --- Helper: Get a canonical, absolute path for a file/symlink ---
# This avoids `realpath` and manually canonicalizes the path, which is necessary
# to reliably detect cycles (e.g. "link" vs "./link").
get_canonical_path() {
    local path="$1"
    local base
    local dir
    
    # If path is relative, make it absolute first
    if [[ "$path" != /* ]]; then
        path="$(pwd)/$path"
    fi
    
    base=$(basename "$path")
    dir=$(dirname "$path")
    
    # Use subshell to not change script's CWD
    # The `cd` can fail if the link is broken mid-chain
    if ! canonical_dir=$(cd "$dir" 2>/dev/null && pwd); then
        echo "Error: Broken link detected. Cannot resolve directory '$dir' in path '$path'." >&2
        exit 1
    fi
    
    echo "$canonical_dir/$base"
}

# --- Helper function for cycle detection and reporting ---
detect_and_report_cycle() {
    local next_path=$1
    local -n path_chain=$2 # Use nameref for the chain array

    for i in "${!path_chain[@]}"; do
        if [[ "${path_chain[$i]}" == "$next_path" ]]; then
            echo "Error: Circular link detected." >&2
            
            loop_part=("${path_chain[@]:i}")
            
            loop_str=""
            for item in "${loop_part[@]}"; do
                loop_str+="$item -> "
            done
            loop_str+="$next_path"

            echo "Loop detected: $loop_str" >&2
            echo "First repeating node: $next_path" >&2
            exit 1
        fi
    done
}

# --- Main logic ---
current_path="$symlink"
current_depth=0
chain=()

# --- -d/--depth logic ---
if [ "$exact_depth" -ne -1 ]; then
    for ((i=0; i < exact_depth; i++)); do
        canonical_current_path=$(get_canonical_path "$current_path")
        detect_and_report_cycle "$canonical_current_path" chain
        chain+=("$canonical_current_path")

        if [ ! -L "$current_path" ]; then
            echo "Error: Link resolution ended at depth $i, before reaching the required depth of $exact_depth." >&2
            exit 1
        fi
        target=$(readlink "$current_path")
        
        if [[ "$target" == /* ]]; then
            current_path="$target"
        else
            link_dir=$(dirname "$current_path")
            current_path="$link_dir/$target"
        fi
    done
    echo "$(get_canonical_path "$current_path")"
    exit 0
fi

# --- Default and -v/-m logic ---
while [ -L "$current_path" ]; do
    canonical_current_path=$(get_canonical_path "$current_path")
    detect_and_report_cycle "$canonical_current_path" chain

    if [ "$max_depth" -ne -1 ] && [ "$current_depth" -ge "$max_depth" ]; then
        break
    fi

    chain+=("$canonical_current_path")
    target=$(readlink "$current_path")

    if [[ "$target" == /* ]]; then
        current_path="$target"
    else
        link_dir=$(dirname "$current_path")
        current_path="$link_dir/$target"
    fi
    
    ((current_depth++))
done

final_path=$(get_canonical_path "$current_path")

if ! $verbose; then
    echo "$final_path"
else
    output_str=""
    for item in "${chain[@]}"; do
        output_str+="$item -> "
    done
    
    status=""
    if [ "$max_depth" -ne -1 ] && [ "$current_depth" -ge "$max_depth" ]; then
        if [ -L "$current_path" ]; then
            status="(symlink)"
        else
            status="(done)"
        fi
    else
      status="(done)"
    fi

    if [ ${#chain[@]} -gt 0 ]; then
        echo "${output_str% -> } --> $final_path $status"
    else
        initial_canonical_path=$(get_canonical_path "$symlink")
        echo "$initial_canonical_path --> $final_path $status"
    fi
fi

exit 0