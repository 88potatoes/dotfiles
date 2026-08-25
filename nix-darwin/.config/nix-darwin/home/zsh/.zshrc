# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# secrets
if [ -f ~/.env_secrets ]; then
    source ~/.env_secrets
fi

# Path to your oh-my-zsh installation.
# export ZSH="$HOME/.oh-my-zsh"

# --- VERSION MANAGERS START ---
#
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# PYENV (Python Version Manager)
# export PYENV_ROOT="$HOME/.pyenv"
# [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init - zsh)"

# CHRUBY (Ruby Version Manager)
# source /opt/homebrew/opt/chruby/share/chruby/chruby.sh

# --- VERSION MANAGERS END ---

ZSH_THEME="powerlevel10k/powerlevel10k"

zstyle ':omz:lib:nvm' load no
# source $ZSH/oh-my-zsh.sh

# User configuration

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export PATH="$PATH":"$HOME/.pub-cache/bin"

# Nix system profile
if [ -d /run/current-system/sw/bin ]; then
  export PATH="/run/current-system/sw/bin:$PATH"
fi

# editor
alias v='nvim'

# git
gcam='git commit -a -m'
alias gs='git status'
alias gp='git push'
alias gl='git loga'
alias gd='git diff'
alias gvr="gh pr view -w"
alias gdc="git diff --cached"
alias vim="nvim"
# end git

alias zl='zellij list-sessions'
alias zd='zellij delete-session'
alias zk='zellij kill-session'
alias za='zellij attach'

alias spt="TERM=tmux-256color spotify_player"
alias zel="zellij -l welcome"
alias v="nvim"
alias grm="git restore --source=main"

alias secret="openssl rand -base64 32"

export PATH="$HOME/.cargo/bin:$PATH"
export PATH="/Applications/Alacritty.app/Contents/MacOS:$PATH"
export PATH="$HOME/dotfiles/scripts:$PATH"

# Tab completion (required before fzf/bun completions register via compdef)
autoload -Uz compinit && compinit

source <(fzf --zsh)

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
# Zsh plugins (from nixpkgs)
for f in /nix/store/*-zsh-autosuggestions*/share/zsh-autosuggestions/zsh-autosuggestions.zsh(N); do
  [[ -f $f ]] && source $f && break
done
for f in /nix/store/*-zsh-syntax-highlighting*/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh(N); do
  [[ -f $f ]] && source $f && break
done

if [ -f ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi

# Java
if [ -d /run/current-system/sw/bin/java ]; then
  export PATH="/run/current-system/sw/bin:$PATH"
fi

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PATH="$HOME/.local/share/mise/shims:$PATH"
eval "$(mise activate zsh)"
# Apply mise env immediately. Otherwise fresh shells can show a prompt before the
# first precmd/chpwd hook adds repo-local tools like node from .nvmrc.
if typeset -f _mise_hook >/dev/null; then
  _mise_hook
fi
export PATH="$HOME/.local/share/bob/nvim-bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export DOCKER_HOST=unix://${HOME}/.colima/default/docker.sock

wtfev() {
  # Fail instantly if no branch name ($1) is provided
  if [ -z "$1" ]; then
    echo "❌ Error: You must provide a branch name! Usage: wtfev <branch-name>"
    return 1
  fi

    cd ~/Code/scribe-fe-v2 && git checkout main && git pull && wt switch -c "$1"
}

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# Force pi to use brew path
pi () {
  /opt/homebrew/bin/pi "$@"
}

# Nix rebuild + restow
# Usage: nix-reload           → reads profile from ~/.config/nix-profile
#        nix-reload WorkMac   → override with #WorkMac
nix-reload() {
  local profile="${1:-$(cat ~/.config/nix-profile 2>/dev/null)}"
  if [[ -z "$profile" ]]; then
    echo 'Error: ~/.config/nix-profile not found. Create it with your profile name (e.g. Mac or WorkMac), or pass one explicitly.' >&2
    return 1
  fi
  echo "Rebuilding nix profile: $profile"
  sudo -v # cache credentials once for darwin-rebuild
  mkdir -p ~/.config
  echo "$profile" > ~/.config/nix-profile
  darwin-rebuild switch --flake "$HOME/dotfiles/nix-darwin/.config/nix-darwin#$profile"
  stow -d "$HOME/dotfiles" local-bin pi
}
