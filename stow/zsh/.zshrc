# Homebrew env (Apple Silicon default)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

path_prepend_unique() {
  local dir="$1"
  [[ -n "$dir" && -d "$dir" ]] || return 0
  if [[ ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
  fi
}

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
if command -v mise >/dev/null 2>&1; then
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

# Force zellij to use stow-managed config path
export ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"

# Auto-start zellij for interactive Ghostty shells.
# Opt out per-shell with: NO_AUTO_ZELLIJ=1 zsh
if command -v zellij >/dev/null 2>&1; then
  if [[ $- == *i* ]] && [[ -t 1 ]] && [[ "${TERM_PROGRAM:-}" == "ghostty" ]] && [[ -z "${ZELLIJ:-}" ]] && [[ -z "${TMUX:-}" ]] && [[ "${NO_AUTO_ZELLIJ:-0}" != "1" ]]; then
    _active_zellij_session="$(zellij ls --no-formatting 2>/dev/null | awk 'NF && $0 !~ /EXITED/ {print $1; exit}')"
    if [[ -n "$_active_zellij_session" ]]; then
      exec zellij attach "$_active_zellij_session"
    else
      exec zellij attach -c main
    fi
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
  source <(fzf --zsh)
fi

# CLI-specific completions
if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion zsh)
fi

if command -v docker >/dev/null 2>&1; then
  source <(docker completion zsh)
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise completion zsh)"
fi

# Prefer bat over cat when available
if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
fi

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
  alias ll='eza -la --group-directories-first --icons=auto'
  alias la='eza -a --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto'
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
fi

if command -v docker >/dev/null 2>&1; then
  alias d='docker'
fi

if command -v lazydocker >/dev/null 2>&1; then
  alias lzd='lazydocker'
fi

if command -v spotify_player >/dev/null 2>&1; then
  alias spt='spotify_player'
fi

if [[ -d "/Applications/Spotify.app" ]]; then
  alias spotify='open -a Spotify'
fi

# AI + cloud aliases
if command -v codex >/dev/null 2>&1; then
  alias cx='codex'
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
