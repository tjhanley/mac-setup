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
