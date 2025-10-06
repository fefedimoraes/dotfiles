# Set PATH, MANPATH, etc., for Homebrew
export HOMEBREW_NO_AUTO_UPDATE=1 # Do not update on install

[ -f /apollo/env/envImprovement/var/zshrc ] && source /apollo/env/envImprovement/var/zshrc
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)" # Apple Silicon
[ -f /usr/local/Homebrew/bin/brew ] && eval "$(/usr/local/Homebrew/bin/brew shellenv)" # Apple Intel
[ -f /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" # Linux
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH" # Add Homebrew OpenJDK to path

# Start Tmux by default
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  tmux attach || exec tmux new-session && exit
fi

# Install Zinit plugin manager
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Install Tmux plugin manager
TPM_HOME="${HOME}/.tmux/plugins/tpm"
[ ! -d $TPM_HOME ] && mkdir -p "$(dirname $TPM_HOME)"
[ ! -d $TPM_HOME/.git ] && git clone https://github.com/tmux-plugins/tpm "$TPM_HOME"

# Install zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::command-not-found
zinit snippet OMZP::tmux

# Load completions
autoload -U compinit && compinit
zinit cdreplay -q
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Load edit command line in $EDITOR
autoload edit-command-line
zle -N edit-command-line

# Add sbin to path
export PATH="/usr/local/sbin:$PATH"
export EDITOR='nvim'

# Keybindings
bindkey -v
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey -M vicmd v edit-command-line # ESC-v to edit command in $EDITOR

# History
HISTSIZE=5000
HISTFILE="${HOME}/.zsh_history"
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Aliases
alias c='clear'
alias v='nvim'
alias t='btop'
alias lg='lazygit'
alias uid="id -u"
alias gid="id -g"
alias :q="exit"
alias ..="cd .."

alias utc='gdate --utc +%FT%T.%3NZ'
alias now='gdate +%FT%T.%3N%Z'
alias millis='gdate +%s%3N'

function mth() {
  local millis=${1-}

  if [ -z "$millis" ]; then
    script="${0##*/}"
    echo "Returns the ISO date for the provided milliseconds since epoch"
    echo "usage: $script <milliseconds-since-epoch>"
    echo "example: $script 1620418406902"
    return
  fi

  local float=$(echo "scale=3; $millis / 1000" | bc)

  local command="date"
  # add for MacOS portability, requires coreutils to be installed via homebrew
  if [ ! -z "$(which gdate)" ]; then
    command="gdate"
  fi

  $command -u -d "@$float" --iso-8601='seconds'
}

function nowtos() {
  local to=${1-}

  if [ -z "$to" ]; then
    script="${0##*/}"
    echo "Returns the difference between now to the provided date in seconds"
    echo "usage: $script <timestamp>"
    echo "example: $script 2025-09-13T01:02:03.456PDT"
    return
  fi

  local diff=$(( $(gdate +%s -d $to) - $(date +%s) ))
  echo $diff
}

function nowplustos() {
  local offset=${1-}

  if [ -z "$offset" ]; then
    script="${0##*/}"
    echo "Returns the difference between now to the provided offset in seconds"
    echo "usage: $script <offset>"
    echo "example: $script \"5 hours 30 min\""
    return
  fi

  local diff=$(( $(gdate +%s -d "now + $offset") - $(date +%s) ))
  echo $diff
}

alias ld='eza -lD --icons=always'
alias lf='eza -lF --color=always --icons=always | grep -v /'
alias lh='eza -dl .* --group-directories-first --icons=always'
alias ll='eza -al --group-directories-first --icons=always'
alias ls='eza -alF --color=always --icons=always --sort=size | grep -v /'
alias lt='eza -al --sort=modified --icons=always'
alias lstree='eza -al --group-directories-first --icons=always --tree'

alias lsconn="netstat -anvp tcp | awk 'NR<3 || /LISTEN/'"

if command -v bat &> /dev/null; then
  export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
  alias cat='bat'
  alias fzfp='fzf --preview="bat --color=always --style=numbers {}"'
  alias fzfe='nvim $(fzf --preview="bat --color=always --style=numbers {}")'
  alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
  alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'
else
  alias fzfp='fzf --preview="cat {}"'
  alias fzfe='nvim $(fzf --preview="cat {}")'
fi

function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

function ff() {
  aerospace list-windows --all | fzf --bind 'enter:execute(bash -c "aerospace focus --window-id {1}")+abort'
}

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"

# AMZN-specific
if [ "$(whoami)" = "moraesf" ]; then
# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"

export PATH="${HOME}/.pyenv/shims:${PATH}"
export PATH=$PATH:$HOME/.toolbox/bin
export PATH="$PATH:/Users/moraesf/Library/Application Support/JetBrains/Toolbox/scripts"
export DEV_DESKTOP=$USER.aka.corp.amazon.com
export SOCK_FILE=/tmp/ssh-socket-2009-$DEV_DESKTOP

# Aliases
alias startodin='ssh -L 2009:localhost:2009 $DEV_DESKTOP -N -f -T -M -S $SOCK_FILE -o ExitOnForwardFailure=yes'
alias stopodin='ssh -S $SOCK_FILE -O exit $DEV_DESKTOP'
alias checkodin='ssh -S $SOCK_FILE -O check $DEV_DESKTOP'

alias amazon-login="mwinit -f -s"
alias otp-amazon-login="mwinit -o -s"

alias bb=brazil-build
alias cbb='brazil-build clean && brazil-build'
alias bba='brazil-build apollo-pkg'
alias bre='brazil-runtime-exec'
alias brc='brazil-recursive-cmd'
alias bws='brazil ws'
alias bwsuse='bws use --gitMode -p'
alias bwscreate='bws create -n'
alias brc=brazil-recursive-cmd
alias bbr='brc brazil-build'
alias bball='brc --allPackages'
alias bbb='brc --allPackages brazil-build'
alias bbra='bbr apollo-pkg'
alias bbrst='brc brazil-build build'
alias bbbst='brc --allPackages brazil-build build'
alias bwc='brazil-workplace-clean'
alias bsps='brazil setup platform-support'

alias bpc='brazil-package-cache stop; brazil-package-cache start'

alias mossy='/apollo/env/Mossy/bin/mossy'

# Custom Functions
function ada-login() {
  ada credentials update --account=$1 --provider=conduit --role=IibsAdminAccess-DO-NOT-DELETE --once
}

function brazil-workplace-clean() {
  for WORKSPACE in *; do
    if [ -d "${WORKSPACE}" ] && [ -f "${WORKSPACE}/packageInfo" ]; then
      pushd "${WORKSPACE}" >/dev/null
      echo "Cleaning ${WORKSPACE}..."
      bws clean
      popd >/dev/null
    fi
  done
}

function startportforward() {
  ssh -L $1:localhost:$1 $DEV_DESKTOP -N -f -T -M -S /tmp/ssh-socket-$1-$DEV_DESKTOP -o ExitOnForwardFailure=yes
}

function stopportforward() {
  ssh -S /tmp/ssh-socket-$1-$DEV_DESKTOP -O exit $DEV_DESKTOP
}

function checkportforward() {
  ssh -S /tmp/ssh-socket-$1-$DEV_DESKTOP -O check $DEV_DESKTOP
}

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
fi
