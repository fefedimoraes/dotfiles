# Aliases. Loaded before functions/ on purpose: zsh expands aliases when a
# function body is *parsed*, so the global -h/--help aliases below are live while
# the function files are read. functions/repos.zsh quotes its case patterns to
# survive that -- see the comment there before reordering anything.

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
