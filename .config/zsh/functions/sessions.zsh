# Absolute path to this file, captured at source time. sessions-pick's fzf reload
# re-sources it in a fresh non-interactive shell: fzf runs children with
# `$SHELL -c`, which does not inherit shell functions, and a full `zsh -ic` would
# drag in the whole interactive config (fzf's own zsh integration, starship,
# zoxide) just to reprint a session list -- 0.56s versus 0.02s, paid on every
# refresh of a switcher that gets pressed dozens of times a day.
_SESSIONS_ZSH_SRC="${${(%):-%x}:A}"

# Every tmux call below is `command tmux`, never a bare `tmux`. plugins.zsh loads
# OMZP::tmux (.zshrc line 7, BEFORE the functions/ glob on line 13) and that
# plugin defines `alias tmux=_zsh_tmux_plugin_run`. zsh expands aliases while a
# function body is PARSED, so a bare `tmux` here is baked into the body as the
# plugin wrapper for good; `emulate -L zsh` runs far too late to undo it. Same
# reason `cat` is avoided below -- aliases.zsh points it at bat. This is the
# -h/--help alias hazard the README describes, wearing a different hat.

# Shared record producer for sessions-list / sessions-pick.
# Emits one TAB-delimited record per session OTHER than the current one:
#   =name <TAB> attached_mark <TAB> padded_name <TAB> details
#
# Field 1 is deliberately "=name" and not "name": a bare name only PREFIX-matches
# and an ambiguous prefix fails SILENTLY (empty output, status 0), while "=name"
# is an exact match whose failure is loud. fzf expands {1} already shell-quoted,
# so every action downstream targets exactly one session with no extra quoting.
#
# Ordered by #{session_last_attached} descending (most recently used first).
# `tmux list-sessions` sorts alphabetically, which is useless for switching. The
# current session always holds the highest value, so dropping it leaves the
# previously-used session on the top line -- C-j Enter becomes "toggle back".
#
# NOTE: never name a local "path" here -- in zsh it is tied to $PATH, which would
# blank PATH for the whole function and make every command below fail.
function _sessions_records() {
  emulate -L zsh

  local cur
  cur=$(command tmux display-message -p '#S' 2>/dev/null) || return 1
  [ -n "$cur" ] || return 1

  # Glyph as a \u escape so formatters/encodings cannot strip it.
  local g_attached=$'●' # ● a client is attached to this session

  # The -F format needs a REAL tab. tmux does not interpret \t in a format
  # string: it emits a literal backslash-t, which leaves `awk -F'\t'` seeing a
  # single field and silently collapses the list to one column. $'\t' is
  # expanded by zsh long before tmux is exec'd. (\033 is the same trap, which is
  # why the colours below are printf'd by awk rather than set with #[fg=...].)
  local TAB=$'\t'
  local fmt="#{session_last_attached}${TAB}#{session_name}${TAB}"
  fmt+="#{session_windows}${TAB}#{session_attached}${TAB}#{session_path}"

  command tmux list-sessions -F "$fmt" 2>/dev/null |
    sort -rn -t"$TAB" -k1,1 |
    awk -F"$TAB" -v cur="$cur" -v home="$HOME" -v mark_on="$g_attached" '
      # Collect first, print in END: the name column is padded to the widest name
      # and that width is not known until the last record. `column -t` is not an
      # option -- it would eat the tabs fzf needs as --delimiter -- so the width
      # is applied here with %-*s, exactly as _repos_status_records does.
      { if ($2 == cur) next
        n[++c] = $2; w[c] = $3; att[c] = $4; dir[c] = $5
        if (length($2) > mx) mx = length($2) }
      END {
        for (i = 1; i <= c; i++) {
          d = dir[i]
          # #{session_path} really is empty for some sessions (one started with
          # no working directory), so show a placeholder rather than a blank gap.
          if (d == "") d = "-"
          else { sub("^" home, "~", d); sub("^/Volumes/workplace/", "", d) }
          mark = (att[i] + 0 > 0) ? "\033[32m" mark_on "\033[0m" : " "
          printf "=%s\t%s\t%-*s\t\033[2m%2dw\033[0m  \033[34m%s\033[0m\n", \
            n[i], mark, mx, n[i], w[i], d
        }
      }'
}

# List every session except the current one, most recently used first.
# Plain-text counterpart to sessions-pick, and the fallback when fzf is missing.
# Usage: sessions-list [--records]
function sessions-list() {
  emulate -L zsh

  local records=0
  while [[ "$1" == -* ]]; do
    # Patterns are quoted: this config defines global aliases for -h/--help,
    # which would otherwise expand inside these patterns and break parsing.
    case "$1" in
    '--records') records=1; shift ;; # print raw TAB-delimited records (debugging)
    '-h' | '--help') print "usage: sessions-list [--records]"; return 0 ;;
    *) print -u2 "sessions-list: unknown option: $1"; return 2 ;;
    esac
  done

  local -a recs
  recs=(${(f)"$(_sessions_records)"})
  if ((${#recs} == 0)); then
    print -u2 "sessions-list: no other tmux sessions"
    return 1
  fi
  ((records)) && { print -rl -- "${recs[@]}"; return 0; }

  local rec tgt mark nm det
  for rec in "${recs[@]}"; do
    IFS=$'\t' read -r tgt mark nm det <<<"$rec"
    # det already carries its own leading space; the extra literal space here
    # reproduces the two-column gap fzf gets from the record's tab at --tabstop 1.
    printf "%s %s %s\n" "$mark" "$nm" "$det"
  done
}

# Fuzzy-pick another tmux session by NAME, with a preview of what is in it, and
# act on it without leaving the picker.
#   enter  -> switch to the session
#   ctrl-x -> kill it (confirm), then refresh
#   alt-r  -> rename it (prompt), then refresh
#   alt-n  -> create a session named by the current query and switch to it
#   ctrl-r -> refresh    ctrl-/ -> toggle preview
# Usage: sessions-pick
function sessions-pick() {
  emulate -L zsh

  while [[ "$1" == -* ]]; do
    case "$1" in # quoted patterns: see sessions-list
    '-h' | '--help') print "usage: sessions-pick"; return 0 ;;
    *) print -u2 "sessions-pick: unknown option: $1"; return 2 ;;
    esac
  done

  if [ -z "$TMUX" ]; then
    print -u2 "sessions-pick: not inside tmux"
    return 1
  fi

  if ! command -v fzf &>/dev/null; then
    print -u2 "sessions-pick: fzf not found; falling back to sessions-list"
    sessions-list
    return
  fi

  local -a recs
  recs=(${(f)"$(_sessions_records)"})
  if ((${#recs} == 0)); then
    # Only one session exists. Returning non-zero is what keeps the popup on
    # screen long enough to read this -- see the -EE flag on the tmux binding.
    print -u2 "sessions-pick: no other sessions (only $(command tmux display-message -p '#S'))"
    return 1
  fi

  # fzf runs child commands with `$SHELL -c`, which inherits no shell functions,
  # so the reload re-sources just this file instead of starting a full
  # interactive shell. The operand goes through (q) and the whole command through
  # (qq), so a path containing spaces or apostrophes survives intact.
  local _reload_cmd="source ${(q)_SESSIONS_ZSH_SRC} && _sessions_records"
  local RELOAD="reload(zsh -c ${(qq)_reload_cmd})"

  # Interpolate PREVIEW/KILL/RENAME BARE into --preview/--bind, never via
  # ${(q)...}: (q) backslash-escapes the braces to \{1\}, and fzf reads a
  # backslash-prefixed placeholder as escaped, passing the literal text "{1}".
  #
  # {1} is '=notes'; {1}: is '=notes':, because fzf appends the colon OUTSIDE
  # its own quoting. That distinction is load-bearing. display-message and
  # capture-pane take a target-PANE, and for them `-t '=notes'` resolves to
  # nothing at all -- silently for display-message, "can't find pane" for
  # capture-pane. The trailing colon pins the target to "that session, active
  # window, active pane" while still rejecting an ambiguous prefix. Commands that
  # take a target-SESSION (switch-client, kill-session, rename-session) use the
  # bare {1}.
  #
  # Colours are printf escapes, not tmux #[fg=...] tags: display-message and
  # list-windows print those tags LITERALLY, they only render in status contexts.
  local PREVIEW='
    tgt={1}:
    printf "\033[1;36m%s\033[0m\n\033[2m%s\033[0m\n\n" \
      "$(command tmux display-message -p -t "$tgt" "#{session_name}")" \
      "$(command tmux display-message -p -t "$tgt" "#{session_windows}w · #{?session_attached,attached,detached} · #{?session_path,#{session_path},-}")"
    command tmux list-windows -t "$tgt" \
      -F "#{?window_active,1,0} #{window_index}: #{window_name} (#{pane_current_command})" |
      while read -r act rest; do
        if [ "$act" = 1 ]; then printf "\033[33m▸ %s\033[0m\n" "$rest"
        else printf "\033[2m· %s\033[0m\n" "$rest"; fi
      done
    printf "\n\033[2m── active pane ──\033[0m\n"
    # -e keeps the escapes so true-colour prompts and nvim render under --ansi.
    # Captures are mostly trailing blank lines, so squeeze them and keep the tail
    # that fits the preview window.
    command tmux capture-pane -pe -t "$tgt" |
      grep -v "^[[:space:]]*$" | tail -n "$(( ${FZF_PREVIEW_LINES:-30} - 6 ))"'

  # Killing a session from this list is safe: the current session is never in it,
  # and `detach-on-destroy off` means destroying another session cannot detach
  # this client.
  #
  # The empty guard is not paranoia. tmux resolves `-t ""` to the CURRENT
  # session, and fzf expands {1} to '' when nothing is highlighted -- so without
  # it, ctrl-x on a filtered-to-nothing list would kill the session you are
  # sitting in. ctrl-x rather than a bare x so printable keys still reach the
  # query.
  local KILL='
    if [ -z {1} ]; then exit 0; fi
    printf "kill session %s? [y/N] " {1}
    read -k1 -s ans
    printf "\n"
    case "$ans" in
      y | Y) command tmux kill-session -t {1} 2>&1 | tail -3 ;;
    esac'

  # rename-session takes new-name positionally with no `--` terminator, so a name
  # starting with "-" would be read as a flag: refuse it. tmux silently rewrites
  # ":" and "." to "_" (they are target separators), so the resulting name is
  # echoed back rather than assumed.
  local RENAME='
    if [ -z {1} ]; then exit 0; fi
    printf "rename %s to: " {1}
    read -r newname
    case "$newname" in
      "") ;;
      -*) printf "refused: name may not start with -\n"; read -k1 -s ;;
      *) command tmux rename-session -t {1} "$newname" 2>&1 | tail -3 ;;
    esac'

  # --with-nth hides field 1 (the target) but keeps it available to {1}.
  # --nth indexes the TRANSFORMED line, so --nth 2 is the name (record field 3);
  # that is what stops a query from matching the path or window-count columns.
  # --print-query with --expect puts the query on line 1, the pressed key on
  # line 2 (empty for enter) and the selected record on line 3.
  local raw
  raw=$(printf '%s\n' "${recs[@]}" |
    fzf --ansi --tabstop 1 \
      --delimiter $'\t' --with-nth '2..' --nth 2 \
      --prompt 'session> ' \
      --header 'enter=switch  ctrl-x=kill  alt-r=rename  alt-n=new  ctrl-r=refresh  ctrl-/=preview' \
      --header-first --reverse --no-multi --cycle \
      --preview "$PREVIEW" \
      --preview-window 'right,55%,border-left,wrap' \
      --preview-label ' session ' \
      --print-query --expect=alt-n \
      --bind 'ctrl-/:toggle-preview' \
      --bind "ctrl-r:$RELOAD" \
      --bind "ctrl-x:execute($KILL)+$RELOAD" \
      --bind "alt-r:execute($RENAME)+$RELOAD")

  local -a lines
  lines=("${(@f)raw}")
  local query="${lines[1]}" key="${lines[2]}" rec="${lines[3]}"

  # alt-n: create and switch. Handled out here rather than with become() so the
  # name can be validated and a failure can actually be reported.
  if [ "$key" = alt-n ]; then
    local newname="$query"
    if [ -z "$newname" ]; then
      print -n "New session name: "
      read -r newname
    fi
    case "$newname" in
    '') return 0 ;;
    -*) print -u2 "sessions-pick: name may not start with -"; return 1 ;;
    esac
    # new-session -A would ATTACH, which is wrong from inside a popup; checking
    # first and switching explicitly keeps this client's session change clean.
    # The "=" makes both lookups exact.
    if ! command tmux has-session -t "=$newname" 2>/dev/null; then
      command tmux new-session -d -s "$newname" || {
        print -u2 "sessions-pick: could not create session: $newname"
        return 1
      }
    fi
    command tmux switch-client -t "=$newname" || return 1
    return 0
  fi

  # Cancelled (Esc/ctrl-c) or no match: both leave rec empty. Returning 0 is what
  # stops -EE from holding the popup open after a deliberate cancel; only the
  # real errors above return non-zero.
  [ -n "$rec" ] || return 0

  # Field 1 of the record is the exact target, already in "=name" form.
  local tgt="${rec%%$'\t'*}"
  command tmux switch-client -t "$tgt" || {
    print -u2 "sessions-pick: could not switch to $tgt"
    return 1
  }
}
