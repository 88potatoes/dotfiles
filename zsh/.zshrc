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

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search tmux)
source $ZSH/oh-my-zsh.sh

# User configuration

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

alias pyenv="python3 -m venv .venv && source .venv/bin/activate"

source /opt/homebrew/opt/chruby/share/chruby/chruby.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

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

# pnpm
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="/Applications/Alacritty.app/Contents/MacOS:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FZF_DEFAULT_COMMAND='fd --type file --hidden --follow --exclude .git'
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

function ma () {
  local dir_path="$HOME/Codestuff/$1"
  mkdir -p "$dir_path"
  cd "$dir_path"
  nvim .
}

clear

# Added by Windsurf
export PATH="/Users/ericlang/.codeium/windsurf/bin:$PATH"

eval "$(zoxide init zsh)"
