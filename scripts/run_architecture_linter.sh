#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
default_build_root="$repo_root/.build"
low_disk_warn_kb="${ARCH_LINTER_LOW_DISK_WARN_KB:-2097152}"
current_swiftpm_pid=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [--help]

Options:
  -h, --help             Show this help text.

Environment:
  ARCH_LINTER_LOW_DISK_WARN_KB
      Warn when available disk space drops below this many kilobytes.
      Default: 2097152 (2 GiB).
EOF
}

log_warn() {
    printf 'warning: %s\n' "$*" >&2
}

log_info() {
    printf 'info: %s\n' "$*" >&2
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "Unknown argument: $1"
                ;;
        esac
    done
}

warn_low_disk() {
    local target_path="$1"
    local available_kb

    available_kb="$(df -Pk "$target_path" | awk 'NR == 2 { print $4 }')"
    [[ -n "$available_kb" ]] || return 0

    if (( available_kb < low_disk_warn_kb )); then
        log_warn "Low disk headroom detected for $(df -Pk "$target_path" | awk 'NR == 2 { print $6 }'): ${available_kb} KB available. SwiftPM verification may fail or thrash caches."
    fi
}

find_orphaned_helpers() {
    ps -ax -o pid=,ppid=,command= | awk -v repo_root="$repo_root" '
        $2 == 1 && $0 ~ /swiftpm-testing-helper/ && index($0, repo_root) {
            sub(/^[[:space:]]+/, "", $0)
            print $0
        }
    '
}

preflight_orphan_check() {
    local orphaned_helpers

    orphaned_helpers="$(find_orphaned_helpers)"
    [[ -z "$orphaned_helpers" ]] && return 0

    printf 'error: found orphaned swiftpm-testing-helper process(es) for this repository.\n' >&2
    printf '%s\n' "$orphaned_helpers" >&2
    printf 'error: clear the orphaned helper(s) before running verification against the shared .build directory.\n' >&2
    exit 1
}

descendant_pids() {
    local root_pid="$1"

    ps -ax -o pid=,ppid= | awk -v root="$root_pid" '
        {
            pid = $1
            ppid = $2
            children[ppid] = children[ppid] " " pid
        }
        END {
            queue[1] = root
            head = 1
            tail = 1

            while (head <= tail) {
                current = queue[head++]
                split(children[current], ids, " ")
                for (i in ids) {
                    if (ids[i] == "") {
                        continue
                    }
                    queue[++tail] = ids[i]
                    print ids[i]
                }
            }
        }
    '
}

cleanup_current_swiftpm_tree() {
    local root_pid="${current_swiftpm_pid:-}"
    local pid
    local descendants=()

    [[ -n "$root_pid" ]] || return 0
    kill -0 "$root_pid" 2>/dev/null || return 0

    mapfile -t descendants < <(descendant_pids "$root_pid")

    for pid in "${descendants[@]}"; do
        kill -TERM "$pid" 2>/dev/null || true
    done
    kill -TERM "$root_pid" 2>/dev/null || true

    sleep 1

    for pid in "${descendants[@]}"; do
        kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
    done
    kill -0 "$root_pid" 2>/dev/null && kill -KILL "$root_pid" 2>/dev/null || true
}

handle_interrupt() {
    log_warn "Interrupted. Cleaning up active SwiftPM subprocess tree."
    cleanup_current_swiftpm_tree
    exit 130
}

cleanup_generated_artifacts() {
    cleanup_current_swiftpm_tree
    rm -rf "$default_build_root" "$repo_root/.build-architecture-linter-isolated"
}

run_swiftpm() {
    current_swiftpm_pid=""
    "$@"
}

parse_args "$@"

trap cleanup_generated_artifacts EXIT
trap handle_interrupt INT TERM

module_cache_dir="$default_build_root/module-cache"
swiftpm_cache_dir="$default_build_root/swiftpm-cache"

mkdir -p "$module_cache_dir" "$swiftpm_cache_dir"

export CLANG_MODULE_CACHE_PATH="$module_cache_dir"
export SWIFTPM_MODULECACHE_OVERRIDE="$module_cache_dir"
export XDG_CACHE_HOME="$swiftpm_cache_dir"

warn_low_disk "$repo_root"
preflight_orphan_check

swiftpm_args=(--package-path "$repo_root")
run_swiftpm swift test "${swiftpm_args[@]}"
run_swiftpm swift run "${swiftpm_args[@]}" architecture-linter "$repo_root"
