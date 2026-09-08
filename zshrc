
export PATH="$HOME/.local/bin:$PATH"
export SHELL="${SHELL-/bin/zsh}"
export OS="${OS-$(uname)}"
export COLORTERM=truecolor
export TERM="xterm-256color"
export HISTSIZE=200000
export SAVEHIST=200000
export HISTFILE=~/.zsh_history
setopt EXTENDED_HISTORY

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

export PATH="$HOME/.cargo/bin:$PATH"
export FZF_DEFAULT_COMMAND="fd --type file --color=always"
export FZF_DEFAULT_OPTS="--ansi"
export ZSH_CACHE_DIR="${XDG_CACHE_HOME-"$HOME/.cache"}/zsh"
fpath+=("$HOME/.local/share/zsh/site-functions")

export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

export CLICOLOR=1
export VISUAL='hx'
export EDITOR='hx'

bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^r' history-incremental-search-backward

if [ $commands[eza] ]; then
  alias l='eza -lh --git --icons --group-directories-first --group --header'
  alias la='eza -lah --git --icons --group-directories-first'
  alias ll='eza -lh --git --icons --group-directories-first'
  alias ls='eza -G --icons --group-directories-first'
  alias lsa='eza -lah --git --icons --group-directories-first'
  alias tree='eza --tree --icons --group-directories-first'
fi

eval "$(starship init zsh)"