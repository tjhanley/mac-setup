# One-time PATH and tool initialisation — guarded so source ~/.zshrc is safe
if [[ -z "$_ZSHRC_INITIALIZED" ]]; then
  _ZSHRC_INITIALIZED=1

  # Build system PATH from /etc/paths + /etc/paths.d/ (normally done by
  # /etc/zprofile for login shells — zellij/tmux spawn non-login shells)
  if [[ -x /usr/libexec/path_helper ]]; then
    eval "$(/usr/libexec/path_helper -s)"
  fi

  # Homebrew env (Apple Silicon default)
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# History
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "$(dirname "$HISTFILE")" ]] || mkdir -p "$(dirname "$HISTFILE")"
HISTSIZE=50000
SAVEHIST=50000
setopt append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks

# Shell options
setopt auto_cd
setopt extended_glob
setopt correct

path_prepend_unique() {
  local dir="$1"
  [[ -n "$dir" && -d "$dir" ]] || return 0
  if [[ ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
  fi
}

# CLI completions — dump to fpath before compinit so they lazy-load correctly
_comp_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$_comp_cache"

if command -v kubectl >/dev/null 2>&1; then
  [[ -f "$_comp_cache/_kubectl" ]] || kubectl completion zsh > "$_comp_cache/_kubectl"
fi
if command -v docker >/dev/null 2>&1; then
  [[ -f "$_comp_cache/_docker" ]] || docker completion zsh > "$_comp_cache/_docker"
fi
if command -v mise >/dev/null 2>&1; then
  [[ -f "$_comp_cache/_mise" ]] || mise completion zsh > "$_comp_cache/_mise"
fi
if command -v gh >/dev/null 2>&1; then
  [[ -f "$_comp_cache/_gh" ]] || gh completion -s zsh > "$_comp_cache/_gh"
fi
if command -v stern >/dev/null 2>&1; then
  [[ -f "$_comp_cache/_stern" ]] || stern --completion zsh > "$_comp_cache/_stern"
fi
if command -v rustup >/dev/null 2>&1; then
  [[ -f "$_comp_cache/_rustup" ]] || rustup completions zsh > "$_comp_cache/_rustup"
  [[ -f "$_comp_cache/_cargo" ]] || rustup completions zsh cargo > "$_comp_cache/_cargo"
fi

fpath=("$_comp_cache" $fpath)
unset _comp_cache

# zsh completion core
autoload -Uz compinit
zmodload zsh/complist
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"

# Better completion UX
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# fzf-tab completion menu
for _fzf_tab in \
  /opt/homebrew/share/fzf-tab/fzf-tab.plugin.zsh \
  /usr/local/share/fzf-tab/fzf-tab.plugin.zsh; do
  if [[ -f "$_fzf_tab" ]]; then
    source "$_fzf_tab"
    break
  fi
done
unset _fzf_tab

# mise runtime manager
if [[ -z "$_MISE_INITIALIZED" ]] && command -v mise >/dev/null 2>&1; then
  _MISE_INITIALIZED=1
  eval "$(mise activate zsh)"
fi

# Rust toolchain
if [[ -d "$HOME/.cargo/bin" ]]; then
  path_prepend_unique "$HOME/.cargo/bin"
elif command -v rustup >/dev/null 2>&1; then
  _rustup_cargo="$(rustup which cargo 2>/dev/null || true)"
  if [[ -n "$_rustup_cargo" && -x "$_rustup_cargo" ]]; then
    path_prepend_unique "$(dirname "$_rustup_cargo")"
  fi
  unset _rustup_cargo
fi

# Local bin (mise shims, pipx, user scripts, etc.)
path_prepend_unique "$HOME/.local/bin"

# Tool config paths
export ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"


# Auto-start zellij for interactive Ghostty shells.
# Opt out per-shell with: NO_AUTO_ZELLIJ=1 zsh
if command -v zellij >/dev/null 2>&1; then
  if [[ $- == *i* ]] && [[ -t 1 ]] && [[ "${TERM_PROGRAM:-}" == "ghostty" ]] && [[ -z "${ZELLIJ:-}" ]] && [[ -z "${TMUX:-}" ]] && [[ "${NO_AUTO_ZELLIJ:-0}" != "1" ]]; then
    exec zellij
  fi
fi

# Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# zoxide smart cd
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# FZF
if command -v fzf >/dev/null 2>&1; then
  # fzf >= 0.57 builds ctrl-r from zsh's $history parameter, which omits
  # commands imported from other sessions via share_history; disabling the
  # perl branch forces the fc-based fallback, which includes them
  source <(fzf --zsh | sed 's/(( ${+commands\[perl\]} ))/false/')
  export FZF_DEFAULT_OPTS=" \
    --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
    --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
    --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
    --color=selected-bg:#45475A \
    --color=border:#6C7086,label:#CDD6F4"
fi

# Git aliases (OMZ-style)
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch --all'
alias gc='git commit'
alias gcmsg='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch'
alias gl='git pull'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias glog='git log --oneline --graph --decorate'
alias gloga='git log --oneline --graph --decorate --all'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gst='git status'
alias gsw='git switch'
alias gswc='git switch -c'

# Dot navigation (.., ..., ....)
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias l='ls -lah'

# Editor defaults
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL="nvim"
  alias vim='nvim'
  alias vi='nvim'
fi

# eza replaces ls (if installed)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -la --group-directories-first --icons=auto --git --header --time-style=relative'
  alias la='eza -a --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto --git --git-ignore'
fi

# Common tool aliases
if command -v yazi >/dev/null 2>&1; then
  function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
  compdef y=yazi
fi

if command -v lazygit >/dev/null 2>&1; then
  alias lg='lazygit'
fi

if command -v zellij >/dev/null 2>&1; then
  alias zj='zellij'
  alias zja='zellij attach -c main'
  alias zka='zellij kill-all-sessions'
fi

if command -v docker >/dev/null 2>&1; then
  alias d='docker'
fi

if command -v claude >/dev/null 2>&1; then
  alias cc='claude'
  alias ccw='claude --worktree'
fi

if command -v lazydocker >/dev/null 2>&1; then
  alias lzd='lazydocker'
fi

# Re-stow a single package from mac-setup
restow() { stow -R "$1" -d ~/Workspace/mac-setup/stow -t ~; }

# Caffeinate helpers — prevent sleep for common durations
single()  { caffeinate -dis -t 3600  & print -P "%F{green}✓%f single shot: awake for 1 hour (pid $!)"; }
double()  { caffeinate -dis -t 10800 & print -P "%F{green}✓%f double shot: awake for 3 hours (pid $!)"; }
redbull() { caffeinate -dis -t 86400 & print -P "%F{green}✓%f redbull: awake for 24 hours (pid $!)"; }
decaf()   { pkill caffeinate 2>/dev/null && print -P "%F{green}✓%f caffeine cleared" || print "no caffeinate running"; }

if [[ -d "/Applications/Spotify.app" ]]; then
  alias spotify='open -a Spotify'
fi

# AI + cloud aliases
if command -v codex >/dev/null 2>&1; then
  alias cx='codex'
fi

if command -v opencode >/dev/null 2>&1; then
  alias oc='opencode'
fi

if command -v claude >/dev/null 2>&1; then
  alias cc='claude'
fi

if command -v kubectl >/dev/null 2>&1; then
  alias k='kubectl'
fi

if command -v gcloud >/dev/null 2>&1; then
  if command -v mise >/dev/null 2>&1; then
    _mise_python="$(mise which python 2>/dev/null || true)"
    if [[ -n "$_mise_python" && -x "$_mise_python" ]]; then
      export CLOUDSDK_PYTHON="$_mise_python"
    fi
    unset _mise_python
  fi

  for _gcloud_sdk in \
    /usr/local/share/google-cloud-sdk \
    /opt/homebrew/share/google-cloud-sdk \
    "$HOME/google-cloud-sdk"; do
    if [[ -f "$_gcloud_sdk/path.zsh.inc" ]]; then
      source "$_gcloud_sdk/path.zsh.inc"
    fi
    if [[ -f "$_gcloud_sdk/completion.zsh.inc" ]]; then
      source "$_gcloud_sdk/completion.zsh.inc"
    fi
  done
  unset _gcloud_sdk

  alias gal='gcloud auth login'
fi

# zsh plugins loaded last
for _zsh_auto in \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  if [[ -f "$_zsh_auto" ]]; then
    source "$_zsh_auto"
    break
  fi
done
unset _zsh_auto

for _zsh_syntax in \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if [[ -f "$_zsh_syntax" ]]; then
    source "$_zsh_syntax"
    break
  fi
done
unset _zsh_syntax
unset -f path_prepend_unique

# Refresh ~/.secrets from Dashlane vault.
# Requires: dcli authenticated, ~/.secrets-config with KEY=dl://title/field lines.
# Copy .secrets-config.example to ~/.secrets-config to get started.
function refresh-secrets() {
  local config="$HOME/.secrets-config"
  local out="$HOME/.secrets"

  if [[ ! -f "$config" ]]; then
    print -P "%F{red}error:%f ~/.secrets-config not found"
    print -P "%F{yellow}hint:%f copy .secrets-config.example to ~/.secrets-config and fill in your Dashlane paths"
    return 1
  fi

  local dcli_bin
  dcli_bin=$(command -v dcli 2>/dev/null) || {
    print -P "%F{red}error:%f dcli not found — run: brew install dashlane/tap/dashlane-cli"
    return 1
  }

  local tmp val
  tmp=$(mktemp)

  {
    echo "# Auto-generated by refresh-secrets — do not edit manually"
    echo "# Refreshed: $(date)"
    echo ""
    while IFS='=' read -r key vault_path; do
      [[ -z "$key" || "$key" == \#* ]] && continue

      # Alias entry (KEY=$OTHER_KEY): mirrors another var instead of hitting the
      # vault. Emitted verbatim so the reference expands when ~/.secrets is
      # sourced, keeping one vault item as the single source of truth. Must be
      # listed after the entry it references.
      if [[ "$vault_path" == \$* ]]; then
        echo "export $key=\"$vault_path\""
        continue
      fi

      val=$("$dcli_bin" read "$vault_path") || {
        print -P "%F{red}error:%f failed to get $key from Dashlane (path: $vault_path)" >&2
        /bin/rm -f "$tmp"
        return 1
      }
      # dcli read sometimes returns full JSON — extract the password field, or
      # the note field for secure notes (long values like JWTs live there).
      if [[ "$val" == \{* ]]; then
        local extracted
        extracted=$(echo "$val" | /usr/bin/sed -n 's/.*"password":"\([^"]*\)".*/\1/p')
        [[ -z "$extracted" ]] && extracted=$(echo "$val" | /usr/bin/sed -n 's/.*"note":"\([^"]*\)".*/\1/p')
        val="$extracted"
      fi

      # TODO(tom): guard against an empty $val here.
      # A vault item can resolve to nothing (wrong field name, blank entry, JSON
      # shape dcli didn't match). dcli exits 0, so the error above never fires and
      # we write `export KEY=""` — replacing a working ~/.secrets with a silently
      # broken one. Decide: abort the whole refresh, or skip this key and warn?

      echo "export $key=\"$val\""
    done < "$config"
  } > "$tmp"

  chmod 600 "$tmp"
  mv "$tmp" "$out"
  source "$out"
  print -P "%F{green}✓%f Secrets refreshed from Dashlane"
}

# Machine-specific secrets and overrides (not tracked in git)
if [[ -f "$HOME/.secrets" ]]; then
  source "$HOME/.secrets"
fi


export AWS_PROFILE=225194532386_PowerUserAccess
# Credentials do NOT belong in this file. ~/.zshrc is a stow symlink into the
# mac-setup repo, so anything exported here becomes tracked content. Secrets
# live in ~/.secrets (gitignored, outside the repo), sourced above and
# regenerated from Dashlane by refresh-secrets.

# AWS SSO login + export creds for Terraform
awsl() {
  aws login --profile "$AWS_PROFILE" && \
  eval "$(aws configure export-credentials --profile "$AWS_PROFILE" --format env)" && \
  print -P "%F{green}✓%f AWS creds exported for $AWS_PROFILE"
}

# OpenClaw Completion
# source "/Users/tom/.openclaw/completions/openclaw.zsh"
export PATH="$HOME/.local/bin:$PATH"

# Auto-fill Sonatus LDAP password from macOS Keychain for jmp-* ssh aliases.
# Seed once: security add-generic-password -a "$USER" -s sonatus-ldap -w
# Falls back to normal ssh if the keychain item is missing.
ssh() {
  if [[ "$1" == jmp-* ]]; then
    local pw
    pw="$(security find-generic-password -a "$USER" -s sonatus-ldap -w 2>/dev/null)"
    if [[ -n "$pw" ]]; then
      SSHPASS="$pw" sshpass -e command ssh "$@"
      return
    fi
  fi
  command ssh "$@"
}

# Per-directory gh account. Exports GH_TOKEN so that both `gh` AND git use the
# right identity, without depending on the global `gh auth switch` state -- git
# routes github.com creds through `!gh auth git-credential` (see
# credential.https://github.com.helper), which honours GH_TOKEN over the active
# account. If the active account drifts, private repos 404 as "Repository not
# found", so nothing here is allowed to fall back to it silently.
#
# Resolution order:  git config gh.user  ->  remote owner  ->  path default.

# GitHub owner -> gh account.
# TODO(tom): add any other orgs you have access to (sonatus-* forks, etc).
typeset -gA GH_ACCOUNT_BY_OWNER=(
  sonatus   tjhanley-snt
  snt-devx  tjhanley-snt
  tjhanley  tjhanley
)

# Fallback for directories that are not inside a git repo yet. This is what
# covers `git clone` of a private repo: there is no remote to derive from until
# the clone finishes, so the enclosing directory decides the identity.
typeset -gA GH_ACCOUNT_BY_PATH=(
  "$HOME/Workspace"  tjhanley-snt
)

typeset -gA _gh_token_cache _gh_warned_owners

# Owner from a remote URL. Handles https, scp-style ssh, and ssh host aliases:
#   https://github.com/sonatus/iac-live.git      -> sonatus
#   git@github.com:tjhanley/necronomicon.git     -> tjhanley
#   git@github.com-personal:tjhanley/mac-setup   -> tjhanley
_gh_remote_owner() {
  local url=${1#*://}   # strip scheme, if any
  url=${url#*@}         # strip user@, if any
  [[ $url == *[:/]* ]] || return 1
  local host=${url%%[:/]*} path=${url#*[:/]}
  [[ $host == github.com || $host == github.com-* ]] || return 1
  path=${path%%/*}
  [[ -n $path ]] && print -r -- $path
}

# These two helpers return values via $REPLY rather than stdout on purpose. A
# `$(...)` call would run them in a subshell, where writes to the cache and the
# warned-owners map are discarded -- which silently defeats both the token cache
# and the warn-once behaviour.

# Sets REPLY to the token for account $1. One `gh auth token` spawn per account
# per shell, not per cd.
_gh_token_for() {
  if [[ -z ${_gh_token_cache[$1]} ]]; then
    _gh_token_cache[$1]=$(gh auth token --user "$1" 2>/dev/null)
  fi
  REPLY=${_gh_token_cache[$1]}
  [[ -n $REPLY ]]
}

# Sets REPLY to the account for $PWD. Returns non-zero if none applies.
_gh_account_for_pwd() {
  local acct owner url dir
  REPLY=

  # 1. explicit per-repo override always wins
  acct=$(git config gh.user 2>/dev/null)
  [[ -n $acct ]] && { REPLY=$acct; return 0 }

  # 2. derive from the remote's owner
  url=$(git config remote.origin.url 2>/dev/null)
  if [[ -n $url ]] && owner=$(_gh_remote_owner "$url"); then
    acct=${GH_ACCOUNT_BY_OWNER[$owner]}
    [[ -n $acct ]] && { REPLY=$acct; return 0 }
    # A github.com remote we have no mapping for. Warn once per owner per shell
    # so an unmapped private repo does not present as a phantom 404.
    if [[ -o interactive && -z ${_gh_warned_owners[$owner]} ]]; then
      _gh_warned_owners[$owner]=1
      print -u2 "gh: no account mapped for owner '$owner'; using gh's active account"
    fi
    return 1
  fi

  # 3. not in a git repo with a github remote -- fall back on location
  for dir in ${(k)GH_ACCOUNT_BY_PATH}; do
    if [[ $PWD == $dir || $PWD == $dir/* ]]; then
      REPLY=${GH_ACCOUNT_BY_PATH[$dir]}
      return 0
    fi
  done
  return 1
}

_gh_set_token() {
  local acct
  if _gh_account_for_pwd; then
    acct=$REPLY
    if _gh_token_for "$acct"; then
      export GH_TOKEN=$REPLY
      return
    fi
    [[ -o interactive ]] &&
      print -u2 "gh: no stored token for '$acct'; run: gh auth login --user $acct"
  fi
  unset GH_TOKEN
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _gh_set_token
_gh_set_token

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# --- Claude Code spend audit ------------------------------------------------
# claudespend [DAYS]  re-parse transcripts and print the headline block.
# Defaults to the last 30 days, counting today. Runs in a subshell because the
# audit scripts open turns.csv relative to the current directory: the job has to
# cd, your shell does not.
claudespend() {
  local days=${1:-30}
  local end start
  end=$(date +%Y-%m-%d)
  start=$(date -v-$((days - 1))d +%Y-%m-%d)
  (
    cd ~/claude-spend-audit || return 1
    # Full history on purpose: turns.csv is shared by the other scripts.
    python3 parse_transcripts.py || return 1
    echo
    python3 stats.py --start "$start" --end "$end"
    # stats.py hardcodes a 31-day divisor for its run rate, so recompute it.
    python3 - "$start" "$end" <<'PY'
import csv, datetime, sys
start, end = sys.argv[1], sys.argv[2]
rows = [r for r in csv.DictReader(open('turns.csv')) if start <= r['date'] <= end]
total = sum(float(r['cost_total']) for r in rows)
days = (datetime.date.fromisoformat(end) - datetime.date.fromisoformat(start)).days + 1
print(f"\nCORRECTED run rate: ${total / days * 30:,.2f}/30d over {days} days (${total / days:,.2f}/day)")
PY
  )
}
