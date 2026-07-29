# Start Tmux by default. Keep this early: it exec's into tmux or exits, so any
# expensive setup ahead of it is wasted work on every login.
if command -v tmux &>/dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  tmux attach || exec tmux new-session && exit
fi
