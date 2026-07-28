# Set PATH, MANPATH, etc., for Homebrew
export HOMEBREW_NO_AUTO_UPDATE=1 # Do not update on install

[ -f /apollo/env/envImprovement/var/zshrc ] && source /apollo/env/envImprovement/var/zshrc
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"                           # Apple Silicon
[ -f /usr/local/Homebrew/bin/brew ] && eval "$(/usr/local/Homebrew/bin/brew shellenv)"               # Apple Intel
[ -f /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" # Linux
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"                                                    # Add Homebrew OpenJDK to path

# Start Tmux by default
if command -v tmux &>/dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
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

alias ld='eza -lD --icons=always'
alias lf='eza -lF --color=always --icons=always | grep -v /'
alias lh='eza -dl .* --group-directories-first --icons=always'
alias ll='eza -al --group-directories-first --icons=always'
alias ls='eza -alF --color=always --icons=always --sort=size | grep -v /'
alias lt='eza -al --sort=modified --icons=always'
alias lstree='eza -al --group-directories-first --icons=always --tree'

alias lsconn="netstat -anvp tcp | awk 'NR<3 || /LISTEN/'"

if command -v bat &>/dev/null; then
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

# Global aliases
alias -g NE='2>/dev/null'
alias -g ND='>/dev/null'
alias -g NUL='>/dev/null 2>1'
alias -g JQ='| jq'
alias -g C='| pbcopy'
alias -g L='| less'

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

  local diff=$(($(gdate +%s -d $to) - $(date +%s)))
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

  local diff=$(($(gdate +%s -d "now + $offset") - $(date +%s)))
  echo $diff
}

function rfv() (
  local RELOAD='reload:rg --column --color=always --smart-case {q} || :'
  local OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
            nvim {1} +{2}     # No selection. Open the current line in Vim.
          else
            nvim +cw -q {+f}  # Build quickfix list for the selected items.
          fi'

  fzf --disabled --ansi --multi \
    --bind "start:$RELOAD" --bind "change:$RELOAD" \
    --bind "enter:become:$OPENER" \
    --bind "ctrl-o:execute:$OPENER" \
    --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
    --delimiter : \
    --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
    --preview-window '~4,+{2}+4/3,<80(up)' \
    --query "$*"
)

function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# Show git status of every immediate subdirectory that is a git repo.
# Requires a Nerd Font in the terminal for the glyphs to render.
# Usage: repos-status [-f|--files] [root-dir]
#   * With an arg           -> scans that directory.
#   * No arg, inside a repo -> scans the repo's siblings (its parent dir).
#   * No arg, not in a repo -> scans the current directory.
#   * -f / --files          -> also list changed files, marking staged vs unstaged.
function repos-status() {
  emulate -L zsh

  local g_clean=$''     # nf-fa-check
  local g_dirty=$''     # nf-fa-pencil
  local g_branch=$''    # nf-pl-branch
  local g_ahead=$''     # nf-fa-arrow_up
  local g_behind=$''    # nf-fa-arrow_down
  local g_detached=$''  # nf-fa-chain_broken
  local g_repo=$''      # nf-oct-repo
  local g_staged=$''    # nf-fa-plus_circle        (staged / index)
  local g_unstaged=$''  # nf-fa-exclamation_circle (unstaged / worktree)
  local g_untracked=$'' # nf-fa-question_circle    (untracked)

  local files=0
  while [[ "$1" == -* ]]; do
    # Patterns are quoted: this file defines global aliases for -h/--help,
    # which would otherwise expand inside these patterns and break parsing.
    case "$1" in
    '-f' | '--files') files=1; shift ;;
    '-h' | '--help') print "usage: repos-status [-f|--files] [root-dir]"; return 0 ;;
    *) print -u2 "repos-status: unknown option: $1"; return 2 ;;
    esac
  done

  local root
  if [ -n "$1" ]; then
    root="$1"
  else
    local top
    top=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$top" ]; then root="${top:h}"; else root="$PWD"; fi
  fi

  # Pass 1: collect repo dirs, find the widest name for alignment.
  local d name width=0
  local -a repos names
  for d in "$root"/*/(N); do
    [ -d "$d/.git" ] || continue
    name="${${d%/}:t}"
    repos+=("$d")
    names+=("$name")
    ((${#name} > width)) && width=${#name}
  done

  if ((${#repos} == 0)); then
    print -u2 "repos-status: no git repositories found in $root"
    return 1
  fi

  # Pass 2: query git and print, aligned to the widest name.
  # NOTE: never name a local "path" here -- in zsh it is tied to $PATH, which
  # would blank PATH for the whole function and make every git call fail.
  local i branch dirty ab behind ahead sync line x y relpath sm um
  local -a st
  for i in {1..${#repos}}; do
    d="${repos[$i]}"
    name="${names[$i]}"

    branch=$(git -C "$d" symbolic-ref --short HEAD 2>/dev/null)
    [ -z "$branch" ] && branch="$g_detached $(git -C "$d" rev-parse --short HEAD 2>/dev/null)"

    st=(${(f)"$(git -C "$d" -c core.quotePath=false status --porcelain 2>/dev/null)"})
    dirty=${#st}

    ab=$(git -C "$d" rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)
    behind=${ab%%$'\t'*}
    ahead=${ab##*$'\t'}
    sync=""
    [ -n "$ab" ] && sync="${g_behind}${behind} ${g_ahead}${ahead}"

    if ((dirty == 0)); then
      printf "\033[32m%s\033[0m %s %-*s  %s %-16s %s\n" \
        "$g_clean" "$g_repo" "$width" "$name" "$g_branch" "$branch" "$sync"
      continue
    fi

    printf "\033[33m%s\033[0m %s %-*s  %s %-16s %s \033[33m(%s)\033[0m\n" \
      "$g_dirty" "$g_repo" "$width" "$name" "$g_branch" "$branch" "$sync" "$dirty"

    ((files)) || continue

    # Porcelain v1 status: col 1 = index (staged), col 2 = worktree (unstaged).
    for line in "${st[@]}"; do
      x="${line[1]}"
      y="${line[2]}"
      relpath="${line[4,-1]}"
      if [[ "$x$y" == "??" ]]; then
        printf "      \033[31m%s %s\033[0m  %s\n" "$g_untracked" "??" "$relpath"
      else
        if [[ "$x" != " " ]]; then sm=$'\033[32m'"$g_staged"$'\033[0m'; else sm=" "; fi
        if [[ "$y" != " " ]]; then um=$'\033[33m'"$g_unstaged"$'\033[0m'; else um=" "; fi
        printf "      %s%s %-2s %s\n" "$sm" "$um" "$x$y" "$relpath"
      fi
    done
  done
}

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"

# AMZN-specific
if [ "$(whoami)" = "moraesf" ]; then
  # Added by AIM CLI
  export PATH="$HOME/.aim/mcp-servers:$PATH"
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

  function ada-login-ro() {
    ada credentials update --account=$1 --provider=conduit --role=IibsAdminAccess-DO-NOT-DELETE --once --conduit-read-only
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
fi
