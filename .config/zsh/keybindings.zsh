# Keybindings. The widget must be registered before the bindkey that references
# it. Also keep this file before integrations.zsh: `bindkey -v` switches the
# active keymap, and fzf's own bindings (^R/^T/ESC-c) are installed after it.

# Load edit command line in $EDITOR
autoload edit-command-line
zle -N edit-command-line

bindkey -v
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey -M vicmd v edit-command-line # ESC-v to edit command in $EDITOR
