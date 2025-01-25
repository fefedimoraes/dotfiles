# Start Tmux by default
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  tmux attach || exec tmux new-session && exit
fi

# Set PATH, MANPATH, etc., for Homebrew
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)" # Apple Silicon
[ -f /usr/local/Homebrew/bin/brew ] && eval "$(/usr/local/Homebrew/bin/brew shellenv)" # Intel

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

# Add sbin to path
export PATH="/usr/local/sbin:$PATH"

# Keybindings
bindkey -v
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

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
alias ls='ls --color'
alias ll='ls -lhap --color'
alias v='nvim'
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
export JAVA_HOME="/Library/Java/JavaVirtualMachines/amazon-corretto-11.jdk/Contents/Home"
export PATH="${HOME}/.pyenv/shims:${PATH}"
export PATH=$PATH:$HOME/.toolbox/bin
export PATH="$PATH:/Users/moraesf/Library/Application Support/JetBrains/Toolbox/scripts"
export DEV_DESKTOP=$USER.aka.corp.amazon.com
export SOCK_FILE=/tmp/ssh-socket-2009-$DEV_DESKTOP

# Aliases
alias startodin='ssh -L 2009:localhost:2009 $DEV_DESKTOP -N -f -T -M -S $SOCK_FILE -o ExitOnForwardFailure=yes'
alias stopodin='ssh -S $SOCK_FILE -O exit $DEV_DESKTOP'
alias checkodin='ssh -S $SOCK_FILE -O check $DEV_DESKTOP'

alias amazon-login="mwinit -s"

alias bb=brazil-build
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

# Custom Functions
brazil-workplace-clean() {
for WORKSPACE in *; do
    if [ -d "${WORKSPACE}" ] && [ -f "${WORKSPACE}/packageInfo" ]; then
        pushd "${WORKSPACE}" >/dev/null
        echo "Cleaning ${WORKSPACE}..."
        bws clean
        popd >/dev/null
    fi
done
}

startportforward() {
    ssh -L $1:localhost:$1 $DEV_DESKTOP -N -f -T -M -S /tmp/ssh-socket-$1-$DEV_DESKTOP -o ExitOnForwardFailure=yes
}

stopportforward() {
    ssh -S /tmp/ssh-socket-$1-$DEV_DESKTOP -O exit $DEV_DESKTOP
}

checkportforward() {
    ssh -S /tmp/ssh-socket-$1-$DEV_DESKTOP -O check $DEV_DESKTOP
}
fi
