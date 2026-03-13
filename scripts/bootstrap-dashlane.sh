#!/usr/bin/env zsh
# bootstrap-dashlane.sh — Populate Dashlane Secrets Manager from ~/.secrets-config paths.
#
# Usage:
#   ./scripts/bootstrap-dashlane.sh              # interactive: prompts for each value
#   ./scripts/bootstrap-dashlane.sh --from-file  # reads current values from ~/.secrets
#   ./scripts/bootstrap-dashlane.sh --dry-run    # print what would be created, no writes
#
# Reads KEY=path pairs from ~/.secrets-config (or .secrets-config.example if not present).
# For each entry, creates/updates the secret in Dashlane at the given path.

set -euo pipefail

DRY_RUN=false
FROM_FILE=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --from-file) FROM_FILE=true ;;
    --help|-h)
      sed -n '2,10p' "$0" | sed 's/^# //'
      exit 0 ;;
  esac
done

# ── helpers ────────────────────────────────────────────────────────────────────

print_step()  { print -P "%F{blue}==>%f $*" }
print_ok()    { print -P "%F{green}ok:%f $*" }
print_warn()  { print -P "%F{yellow}warn:%f $*" }
print_error() { print -P "%F{red}error:%f $*" >&2 }

# ── preflight ──────────────────────────────────────────────────────────────────

if ! command -v dcli &>/dev/null; then
  print_error "dcli not found — run: brew install dashlane/tap/dashlane-cli"
  exit 1
fi

if ! dcli account whoami &>/dev/null; then
  print_error "dcli not authenticated — run: dcli login"
  exit 1
fi

# ── config file ────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if [[ -f "$HOME/.secrets-config" ]]; then
  CONFIG="$HOME/.secrets-config"
elif [[ -f "$REPO_ROOT/.secrets-config.example" ]]; then
  print_warn "~/.secrets-config not found — using .secrets-config.example (paths only, no real values)"
  CONFIG="$REPO_ROOT/.secrets-config.example"
else
  print_error "No config found. Copy .secrets-config.example to ~/.secrets-config first."
  exit 1
fi

# ── load existing secrets file if --from-file ──────────────────────────────────

declare -A EXISTING_VALUES
if [[ "$FROM_FILE" == "true" ]]; then
  if [[ ! -f "$HOME/.secrets" ]]; then
    print_error "--from-file: ~/.secrets not found"
    exit 1
  fi
  print_step "Reading current values from ~/.secrets"
  while IFS= read -r line; do
    # match: export KEY="value" or export KEY='value' or export KEY=value
    if [[ "$line" =~ ^export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)=[\"\']?(.*)[\"\']?$ ]]; then
      local_key="${match[1]}"
      local_val="${match[2]}"
      # strip surrounding quotes
      local_val="${local_val%\'}"
      local_val="${local_val%\"}"
      local_val="${local_val#\'}"
      local_val="${local_val#\"}"
      EXISTING_VALUES[$local_key]="$local_val"
    fi
  done < "$HOME/.secrets"
fi

# ── main loop ──────────────────────────────────────────────────────────────────

print_step "Bootstrapping Dashlane secrets from $CONFIG"
[[ "$DRY_RUN" == "true" ]] && print_warn "dry-run mode — no secrets will be written"

created=0
skipped=0

while IFS='=' read -r key path remainder; do
  # skip blank lines and comments
  [[ -z "$key" || "$key" == \#* ]] && continue
  # rejoin path if it contained '=' characters
  [[ -n "$remainder" ]] && path="$path=$remainder"

  local value=""

  if [[ "$FROM_FILE" == "true" ]]; then
    value="${EXISTING_VALUES[$key]-}"
    if [[ -z "$value" ]]; then
      print_warn "$key not found in ~/.secrets — skipping"
      (( skipped++ ))
      continue
    fi
  else
    # prompt interactively (input hidden)
    print -n "$key (Dashlane path: $path) — value (blank to skip): "
    read -rs value
    print ""
    if [[ -z "$value" ]]; then
      print_warn "skipping $key"
      (( skipped++ ))
      continue
    fi
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    print_ok "[dry-run] would create: $path"
    (( created++ ))
    continue
  fi

  # Create or update the secret.
  # dcli secret create uses --title for the secret name/path and reads value from stdin.
  # If the secret already exists this may error — adjust the command if dcli supports upsert.
  # Run `dcli secret --help` to verify syntax for your dcli version.
  if printf '%s' "$value" | dcli secret create "$path" --stdin 2>/dev/null; then
    print_ok "created: $path"
    (( created++ ))
  elif printf '%s' "$value" | dcli secret update "$path" --stdin 2>/dev/null; then
    print_ok "updated: $path"
    (( created++ ))
  else
    print_warn "failed to create/update $path — check: dcli secret --help"
    (( skipped++ ))
  fi

done < "$CONFIG"

print ""
print_step "Done — $created created/updated, $skipped skipped"
