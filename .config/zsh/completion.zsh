# Completions. compinit must run after zsh-completions is loaded (it adds the
# src/ dir to fpath), and zinit cdreplay must run after compinit -- it replays
# the compdef calls the OMZ snippets queued while compdef was still a stub.

# Load completions
autoload -U compinit && compinit
zinit cdreplay -q
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath' # __zoxide_z: see integrations.zsh
