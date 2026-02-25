# Homebrew env (Apple Silicon default)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# mise runtime manager
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# Rust toolchain
if [[ -d "$HOME/.cargo/bin" ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
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
if command -v lazygit >/dev/null 2>&1; then
  alias lg='lazygit'
fi

if command -v zellij >/dev/null 2>&1; then
  alias zj='zellij'
  alias zja='zellij attach -c main'
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
