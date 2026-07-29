# Modular zsh config. The load order below is load-bearing -- each file explains
# its own constraints at the top. See README.md for the layout.
ZSH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

source "$ZSH_CONFIG_DIR/env.zsh"          # PATH first: everything below needs brew
source "$ZSH_CONFIG_DIR/tmux.zsh"         # exec's into tmux; keep before slow work
source "$ZSH_CONFIG_DIR/plugins.zsh"
source "$ZSH_CONFIG_DIR/completion.zsh"   # compinit must follow zsh-completions
source "$ZSH_CONFIG_DIR/options.zsh"
source "$ZSH_CONFIG_DIR/keybindings.zsh"  # bindkey -v before fzf's keybindings
source "$ZSH_CONFIG_DIR/aliases.zsh"      # global -h/--help aliases: see functions/

for _zsh_fn in "$ZSH_CONFIG_DIR"/functions/*.zsh(N); do
  source "$_zsh_fn"
done
unset _zsh_fn

source "$ZSH_CONFIG_DIR/integrations.zsh"

[ -f "$ZSH_CONFIG_DIR/amzn.zsh" ] && source "$ZSH_CONFIG_DIR/amzn.zsh"
