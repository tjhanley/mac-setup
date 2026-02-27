#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
LIST_FILE="${SKIP_WORKTREE_FILE:-$DOTFILES_DIR/.local/skip-worktree.paths}"

usage() {
  cat <<EOF
Usage:
  ./scripts/skip-worktree.sh apply
  ./scripts/skip-worktree.sh clear
  ./scripts/skip-worktree.sh list
  ./scripts/skip-worktree.sh status
  ./scripts/skip-worktree.sh add <path>
  ./scripts/skip-worktree.sh remove <path>

Environment:
  SKIP_WORKTREE_FILE  Override the managed path list file.
                      Default: $LIST_FILE
EOF
}

fail() {
  print -u2 -- "error: $1"
  exit 1
}

ensure_repo_root() {
  git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "DOTFILES_DIR is not a git repository: $DOTFILES_DIR"
}

ensure_list_dir() {
  mkdir -p "$(dirname "$LIST_FILE")"
}

normalize_path() {
  local input="$1"
  local normalized="$input"

  if [[ "$input" = /* ]]; then
    if [[ "$input" == "$DOTFILES_DIR/"* ]]; then
      normalized="${input#$DOTFILES_DIR/}"
    elif [[ "$input" == "$DOTFILES_DIR" ]]; then
      normalized="."
    else
      fail "path is outside repository: $input"
    fi
  fi

  print -- "${normalized#./}"
}

ensure_tracked() {
  local file_path="$1"
  git -C "$DOTFILES_DIR" ls-files --error-unmatch -- "$file_path" >/dev/null 2>&1 \
    || fail "path is not tracked by git: $file_path"
}

read_managed_paths() {
  if [[ ! -f "$LIST_FILE" ]]; then
    return 0
  fi

  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0); print }
  ' "$LIST_FILE"
}

apply_paths() {
  local file_path
  local applied=0
  while IFS= read -r file_path; do
    [[ -z "$file_path" ]] && continue
    ensure_tracked "$file_path"
    git -C "$DOTFILES_DIR" update-index --skip-worktree -- "$file_path"
    print -- "skip-worktree set: $file_path"
    applied=1
  done < <(read_managed_paths)

  [[ "$applied" -eq 0 ]] && print -- "No managed paths found in $LIST_FILE"
  return 0
}

clear_paths() {
  local file_path
  local cleared=0
  while IFS= read -r file_path; do
    [[ -z "$file_path" ]] && continue
    ensure_tracked "$file_path"
    git -C "$DOTFILES_DIR" update-index --no-skip-worktree -- "$file_path"
    print -- "skip-worktree cleared: $file_path"
    cleared=1
  done < <(read_managed_paths)

  [[ "$cleared" -eq 0 ]] && print -- "No managed paths found in $LIST_FILE"
  return 0
}

list_active() {
  git -C "$DOTFILES_DIR" ls-files -v | awk '$1 ~ /^S/ {print $2}'
  return 0
}

status_paths() {
  local file_path
  local any=0

  while IFS= read -r file_path; do
    [[ -z "$file_path" ]] && continue
    any=1
    if git -C "$DOTFILES_DIR" ls-files -v -- "$file_path" | awk '$1 ~ /^S/ {found=1} END {exit found ? 0 : 1}'; then
      print -- "S $file_path"
    else
      print -- "- $file_path"
    fi
  done < <(read_managed_paths)

  [[ "$any" -eq 0 ]] && print -- "No managed paths found in $LIST_FILE"
  return 0
}

add_path() {
  local raw_path="$1"
  local file_path
  file_path="$(normalize_path "$raw_path")"
  ensure_tracked "$file_path"
  ensure_list_dir

  if [[ -f "$LIST_FILE" ]] && awk -v p="$file_path" '
      /^[[:space:]]*#/ { next }
      /^[[:space:]]*$/ { next }
      { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0); if ($0 == p) found=1 }
      END { exit found ? 0 : 1 }
    ' "$LIST_FILE"; then
    print -- "Path already managed: $file_path"
    return 0
  fi

  print -- "$file_path" >> "$LIST_FILE"
  print -- "Added to managed list: $file_path"
}

remove_path() {
  local raw_path="$1"
  local file_path tmp
  file_path="$(normalize_path "$raw_path")"

  [[ -f "$LIST_FILE" ]] || fail "list file does not exist: $LIST_FILE"

  tmp="$(mktemp)"
  awk -v p="$file_path" '
    /^[[:space:]]*#/ { print; next }
    /^[[:space:]]*$/ { print; next }
    {
      line=$0
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line != p) print $0
    }
  ' "$LIST_FILE" > "$tmp"
  mv "$tmp" "$LIST_FILE"
  print -- "Removed from managed list: $file_path"
}

main() {
  ensure_repo_root
  local cmd="${1:-}"

  case "$cmd" in
    apply)
      apply_paths
      ;;
    clear)
      clear_paths
      ;;
    list)
      list_active
      ;;
    status)
      status_paths
      ;;
    add)
      [[ $# -eq 2 ]] || fail "add requires exactly one path"
      add_path "$2"
      ;;
    remove)
      [[ $# -eq 2 ]] || fail "remove requires exactly one path"
      remove_path "$2"
      ;;
    -h|--help|help|"")
      usage
      ;;
    *)
      fail "unknown command: $cmd"
      ;;
  esac
}

main "$@"
