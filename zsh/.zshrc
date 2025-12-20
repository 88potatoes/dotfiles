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
export ZSH="$HOME/.oh-my-zsh"

# --- VERSION MANAGERS START ---
#
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# PYENV (Python Version Manager)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# CHRUBY (Ruby Version Manager)
source /opt/homebrew/opt/chruby/share/chruby/chruby.sh

# --- VERSION MANAGERS END ---

ZSH_THEME="powerlevel10k/powerlevel10k"

source $ZSH/oh-my-zsh.sh

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

# git
gcam='git commit -a -m'
alias gs='git status'
alias gp='git push'
alias gl='git loga'
alias gd='git diff'
alias gvr="gh repo view --web"
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

export PATH="$HOME/.cargo/bin:$PATH"
export PATH="/Applications/Alacritty.app/Contents/MacOS:$PATH"

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
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

if [ -f ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"


# pnpm
export PNPM_HOME="/Users/eric/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

clear


# bun completions
[ -s "/Users/eric/.bun/_bun" ] && source "/Users/eric/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
