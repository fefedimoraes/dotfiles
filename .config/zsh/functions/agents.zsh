# Find and jump between AI coding-agent CLIs running in tmux panes, and resume
# past sessions. Each supported CLI is one file in agents/.
#
# Existence comes from `ps`, never from a CLI's own session registry: such a file
# can be absent, empty or stale while its agents are running. Adapters may only
# DECORATE what the process scan found -- see _agents_<id>_enrich.
#
# #{pane_current_command} is unusable for discovery: it names the pane's
# foreground process, which for a wrapped CLI is the wrapper. Hence the
# pid -> tty -> pane join.
#
# Conventions: `command tmux`, never bare `tmux` -- OMZP::tmux aliases it and zsh
# bakes aliases into a function body at PARSE time (same for `cat`, aliased to
# bat). Locals are never named `path` or `status`; zsh reserves both, so directory
# fields are `dir` and status fields `st` throughout.

# Absolute path to this file: the fzf reloads re-source it in a fresh
# non-interactive shell, since fzf runs children with `$SHELL -c` and inherits no
# functions. Re-sourcing one file beats `zsh -ic`, which would pay for the entire
# interactive config on every refresh. See sessions.zsh.
_AGENTS_ZSH_SRC="${${(%):-%x}:A}"
_AGENTS_DIR="${_AGENTS_ZSH_SRC:h}/agents"

# Cheaper busy signals, all tried and rejected: #{pane_activity} does not exist;
# #{window_activity} is touched for every window at once by a server-wide redraw;
# window_activity_flag needs monitor-activity on, which also lights up the status
# bar; CPU share is backwards for an agent waiting on the network; and matching UI
# strings pins detection to one release of one CLI. _AGENTS_PROBE=0 disables it.
: ${_AGENTS_PROBE:=1}
: ${_AGENTS_PROBE_DELAY:=0.5}

# Searched after PATH. A display-popup runs a NON-interactive zsh, which never
# sources .zshrc, so any directory appended to PATH from there is missing -- which
# is exactly how the plugin this replaces broke: its picker guarded on
# `command -v <cli>` and exited. Only resuming needs a binary; listing does not.
: ${_AGENTS_BIN_HINTS:="$HOME/.toolbox/bin:$HOME/.local/bin:/opt/homebrew/bin"}

# ---------------------------------------------------------------------------
# Registry
# ---------------------------------------------------------------------------

typeset -gA _AGENTS_GLYPH _AGENTS_LABEL _AGENTS_BIN _AGENTS_COMMS
typeset -ga _AGENTS_IDS

# _agents_register <id> [glyph=. label=. bin=. comms=.]
#
# comms is an ERE matched against a process's argv0 basename, and on its own is
# enough for live discovery. key=value so a later capability can be added without
# editing adapters written before it existed.
function _agents_register() {
  emulate -L zsh -o extended_glob   # the ## below needs it; emulate turns it off

  local id="$1"; shift
  if [[ -z "$id" || "$id" != [a-z0-9_-]## ]]; then
    print -u2 "_agents_register: id must match [a-z0-9_-]: ${id:-<empty>}"
    return 2
  fi

  (( ${+_AGENTS_LABEL[$id]} )) || _AGENTS_IDS+=("$id")
  _AGENTS_GLYPH[$id]=''
  _AGENTS_LABEL[$id]="$id"
  _AGENTS_BIN[$id]="$id"
  _AGENTS_COMMS[$id]="$id"

  local kv k v
  for kv in "$@"; do
    k="${kv%%=*}"; v="${kv#*=}"
    case "$k" in
    glyph) _AGENTS_GLYPH[$id]="$v" ;;
    label) _AGENTS_LABEL[$id]="$v" ;;
    bin) _AGENTS_BIN[$id]="$v" ;;
    comms) _AGENTS_COMMS[$id]="$v" ;;
    *) print -u2 "_agents_register: $id: unknown key: $k"; return 2 ;;
    esac
  done
}

function _agents_load() {
  emulate -L zsh
  [[ "$1" == -f ]] || (( $#_AGENTS_IDS == 0 )) || return 0

  _AGENTS_IDS=(); _AGENTS_GLYPH=(); _AGENTS_LABEL=(); _AGENTS_BIN=(); _AGENTS_COMMS=()

  local f
  for f in "$_AGENTS_DIR"/*.zsh(N); do
    source "$f" || print -u2 "agents: failed to load adapter: $f"
  done
}

function _agents_bin() {
  emulate -L zsh
  local id="$1" b="${_AGENTS_BIN[$1]:-$1}" found d

  found=$(command -v "$b" 2>/dev/null) && [[ "$found" == /* ]] && {
    print -r -- "$found"; return 0
  }
  for d in ${(s.:.)_AGENTS_BIN_HINTS}; do
    [[ -x "$d/$b" ]] && { print -r -- "$d/$b"; return 0 }
  done
  return 1
}

# ---------------------------------------------------------------------------
# Snapshots
# ---------------------------------------------------------------------------

typeset -gA _AGENTS_PPID _AGENTS_COMM _AGENTS_TTY _AGENTS_KIDS
typeset -gA _AGENTS_TTY_PANE _AGENTS_PANE_LOC _AGENTS_PANE_DIR

function _agents_ps_snapshot() {
  emulate -L zsh
  _AGENTS_PPID=(); _AGENTS_COMM=(); _AGENTS_TTY=(); _AGENTS_KIDS=()

  local pid ppid tty comm
  # comm is read last so an executable path containing spaces lands in it whole.
  while read -r pid ppid tty comm; do
    [[ -n "$pid" ]] || continue
    _AGENTS_PPID[$pid]="$ppid"
    _AGENTS_COMM[$pid]="${comm:t}"
    _AGENTS_TTY[$pid]="$tty"
    _AGENTS_KIDS[$ppid]="${_AGENTS_KIDS[$ppid]} $pid"
  done < <(ps -Ao pid=,ppid=,tty=,comm= 2>/dev/null)
}

function _agents_pane_snapshot() {
  emulate -L zsh
  _AGENTS_TTY_PANE=(); _AGENTS_PANE_LOC=(); _AGENTS_PANE_DIR=()

  # A real tab: tmux emits a literal backslash-t for "\t" (sessions.zsh).
  local TAB=$'\t'
  local fmt="#{pane_tty}${TAB}#{pane_id}${TAB}"
  fmt+="#{session_name}:#{window_index}.#{pane_index}${TAB}#{pane_current_path}"

  local tty pane loc dir
  while IFS="$TAB" read -r tty pane loc dir; do
    [[ -n "$pane" ]] || continue
    _AGENTS_TTY_PANE[${tty#/dev/}]="$pane"
    _AGENTS_PANE_LOC[$pane]="$loc"
    _AGENTS_PANE_DIR[$pane]="$dir"
  done < <(command tmux list-panes -a -F "$fmt" 2>/dev/null)
}

# The leaf -- the matched descendant with no matched child -- is the canonical
# pid. An agent CLI is often a chain of same-named processes: a wrapper that execs
# a launcher that execs the real binary. Leaf because it is the pid a CLI reports
# in its own registry, so decoration joins cleanly, and because SIGTERM to it
# cascades up as each launcher waits on its child; signalling the outer wrapper
# may instead orphan the process underneath. Chain depth is not assumed.
#
# The tty match is what scopes the walk to one pane's chain; without it a matching
# process elsewhere in the tree can be reached and reported twice.
function _agents_leaf() {
  emulate -L zsh
  local p="$1" tty="$3" kid next
  local anchored="^($2)\$"
  while true; do
    next=''
    for kid in ${=_AGENTS_KIDS[$p]}; do
      [[ "${_AGENTS_TTY[$kid]}" == "$tty" ]] || continue
      if [[ "${_AGENTS_COMM[$kid]}" =~ $anchored ]]; then next="$kid"; break; fi
    done
    [[ -n "$next" ]] || break
    p="$next"
  done
  print -r -- "$p"
}

# ---------------------------------------------------------------------------
# Busy probe
# ---------------------------------------------------------------------------

# Prints: pane_id <TAB> busy|idle. Capturing a pane is cheap; the sleep is not, so
# every pane is sampled, then one sleep, then sampled again.
function _agents_probe() {
  emulate -L zsh
  (( $# )) || return 0

  local -A before
  local p after
  for p in "$@"; do
    before[$p]="$(command tmux capture-pane -p -t "$p" 2>/dev/null)"
  done

  sleep "$_AGENTS_PROBE_DELAY"

  for p in "$@"; do
    after="$(command tmux capture-pane -p -t "$p" 2>/dev/null)"
    if [[ "$after" == "${before[$p]}" ]]; then
      print -r -- "S	$p	idle"
    else
      print -r -- "S	$p	busy"
    fi
  done
}

# ---------------------------------------------------------------------------
# Live records
# ---------------------------------------------------------------------------
#
# Tagged streams, merged in one awk:
#   A  id  pane  loc  pid  status  since  name  cwd     one per running agent
#   E  pane  status  name  session_id  since            adapter decoration
#   S  pane  busy|idle                                  probe results
#   R  id  glyph  label                                 registry
# status is an open vocabulary; "?" means "resolve it for me", "-" means unknown.
#
# Final record, after sort-and-strip:
#   pane  pid  session_id | label  status  age  loc  name  dir
#   ^--- machine ------^    ^------------ displayed ------------^

function _agents_live_producer() {
  emulate -L zsh
  local id re anchored pid leaf tty pane
  local -A seen

  for id in $_AGENTS_IDS; do
    re="${_AGENTS_COMMS[$id]:-$id}"
    anchored="^($re)\$"
    seen=()
    for pid in ${(k)_AGENTS_COMM}; do
      [[ "${_AGENTS_COMM[$pid]}" =~ $anchored ]] || continue

      # Load-bearing, not incidental: a CLI's helper processes can share its
      # executable name, and having no controlling terminal is what excludes them.
      tty="${_AGENTS_TTY[$pid]}"
      [[ -n "$tty" && "$tty" != '??' ]] || continue

      pane="${_AGENTS_TTY_PANE[$tty]}"
      [[ -n "$pane" ]] || continue          # running, but not inside tmux

      # Every member of a chain resolves to the same leaf, so this dedups them.
      leaf=$(_agents_leaf "$pid" "$re" "$tty")
      (( ${+seen[$leaf]} )) && continue
      seen[$leaf]=1

      print -r -- "A	$id	$pane	${_AGENTS_PANE_LOC[$pane]:--}	$leaf	?	0	-	${_AGENTS_PANE_DIR[$pane]:--}"
    done
  done
}

function _agents_live_records() {
  emulate -L zsh
  zmodload -F zsh/datetime p:EPOCHSECONDS 2>/dev/null
  _agents_load

  _agents_ps_snapshot
  _agents_pane_snapshot

  local rawfile="${TMPDIR:-/tmp}/agents-raw.$$"
  {
    _agents_live_producer >|"$rawfile" || return 1
    [[ -s "$rawfile" ]] || return 0

    {
      local id
      for id in $_AGENTS_IDS; do
        print -r -- "R	$id	${_AGENTS_GLYPH[$id]}	${_AGENTS_LABEL[$id]}"
        (( ${+functions[_agents_${id}_enrich]} )) && _agents_${id}_enrich
      done

      if (( _AGENTS_PROBE )); then
        local -a panes
        panes=(${(f)"$(awk -F'\t' '{print $3}' "$rawfile" | sort -u)"})
        _agents_probe "${panes[@]}"
      fi

      command cat -- "$rawfile"
    } | awk -F'\t' -v now="$EPOCHSECONDS" -v home="$HOME" '
      $1 == "R" { glyph[$2] = $3; label[$2] = $4; next }
      $1 == "E" { e_st[$2] = $3; e_nm[$2] = $4; e_sid[$2] = $5; e_since[$2] = $6; next }
      $1 == "S" { probed[$2] = $3; next }
      $1 == "A" {
        n++; p = $3
        pane[n] = p; loc[n] = $4; pid[n] = $5; st[n] = $6; since[n] = $7
        nm[n] = $8; dir[n] = $9

        # Decoration wins over the probe: it is exact, it costs nothing, and its
        # vocabulary is richer -- a CLI can report an agent WAITING on input,
        # which no amount of watching the screen can distinguish from idle.
        if (p in e_st    && e_st[p] != "-")     st[n] = e_st[p]
        if (p in e_nm    && e_nm[p] != "-")     nm[n] = e_nm[p]
        if (p in e_since && e_since[p] + 0 > 0) since[n] = e_since[p]
        sid[n] = (p in e_sid && e_sid[p] != "-") ? e_sid[p] : "-"

        if (st[n] == "?") st[n] = (p in probed) ? probed[p] : "-"

        lbl[n] = (glyph[$2] != "" ? glyph[$2] " " : "") label[$2]
        age[n] = (since[n] + 0 > 0) ? now - since[n] : -1
        if (age[n] < 0 && since[n] + 0 > 0) age[n] = 0

        d = dir[n]
        if (d == "" || d == "-") d = "-"
        else { sub("^" home, "~", d); sub("^/Volumes/workplace/", "", d) }
        dir[n] = d

        if (length(lbl[n]) > wl) wl = length(lbl[n])
        if (length(loc[n]) > wo) wo = length(loc[n])
        if (length(nm[n])  > wn) wn = length(nm[n])
      }
      END {
        # Widths are only known after the last record, and `column -t` would eat
        # the tabs fzf needs as its --delimiter (sessions.zsh). Colours are
        # printf escapes because #[fg=...] prints literally outside a status line.
        for (i = 1; i <= n; i++) {
          s = st[i]
          if      (s == "waiting") { rank = 0; icon = "\033[33m●\033[0m waiting" }
          else if (s == "idle")    { rank = 1; icon = "\033[32m●\033[0m idle   " }
          else if (s == "busy")    { rank = 3; icon = "\033[31m●\033[0m working" }
          else                     { rank = 2; icon = "\033[90m●\033[0m   ?    " }

          printf "%d\t%d\t%s\t%s\t%s\t\033[35m%-*s\033[0m\t%s\t\033[2m%4s\033[0m\t\033[2m%-*s\033[0m\t%-*s\t\033[34m%s\033[0m\n", \
            rank, (age[i] < 0 ? 2147483647 : age[i]), \
            pane[i], pid[i], sid[i], \
            wl, lbl[i], icon, (age[i] < 0 ? "-" : secs2age(age[i])), \
            wo, loc[i], wn, nm[i], dir[i]
        }
      }
      function secs2age(s) {
        if (s < 60)    return s "s"
        if (s < 3600)  return int(s / 60) "m"
        if (s < 86400) return int(s / 3600) "h"
        return int(s / 86400) "d"
      }
    ' | sort -t$'\t' -k1,1n -k2,2n | cut -f3-
  } always {
    command rm -f -- "$rawfile"
  }
}

# ---------------------------------------------------------------------------
# History records
# ---------------------------------------------------------------------------
#
# Adapters emit:  session_id  cwd  mtime  title
# Final record:   id  session_id  cwd  resumable | label  age  title  dir
#
# A CLI with no installed binary still lists its sessions, dimmed and marked
# unresumable: a visible row you cannot act on is information, silence is a bug.

function _agents_history_records() {
  emulate -L zsh
  zmodload -F zsh/datetime p:EPOCHSECONDS 2>/dev/null
  _agents_load

  local id
  for id in $_AGENTS_IDS; do
    (( ${+functions[_agents_${id}_history]} )) || continue
    local resumable=1
    _agents_bin "$id" >/dev/null 2>&1 || resumable=0
    _agents_${id}_history |
      awk -F'\t' -v id="$id" -v r="$resumable" \
          -v glyph="${_AGENTS_GLYPH[$id]}" -v label="${_AGENTS_LABEL[$id]}" \
          '{ printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", id, $1, $2, r, glyph, label, $3, $4 }'
  done |
    awk -F'\t' -v now="$EPOCHSECONDS" -v home="$HOME" '
      { n++
        id[n]=$1; sid[n]=$2; res[n]=$4; mt[n]=$7; ttl[n]=$8

        # cwd is kept raw for `new-window -c` and abbreviated only for display.
        cwd[n]=$3
        d = $3
        if (d == "" || d == "-") d = "-"
        else { sub("^" home, "~", d); sub("^/Volumes/workplace/", "", d) }
        dir[n]=d

        # The suffix is part of the label before the width is measured, or the
        # padding is short by its length on every unresumable row.
        lbl[n] = ($5 != "" ? $5 " " : "") $6 ($4 + 0 ? "" : " (not installed)")

        # Keep the tail of a long directory: the leading components repeat across
        # every row, the trailing ones are what tell them apart. The marker is
        # ASCII because length() counts bytes here, so a multibyte ellipsis would
        # make truncated rows pad two columns short of the others.
        if (length(dir[n]) > 34) dir[n] = ".." substr(dir[n], length(dir[n]) - 31)

        if (length(lbl[n]) > wl) wl = length(lbl[n])
        if (length(dir[n]) > wd) wd = length(dir[n])
      }
      END {
        for (i = 1; i <= n; i++) {
          age = now - mt[i]; if (age < 0) age = 0
          # Dim an unresumable row so the reason is visible before you press
          # enter rather than after.
          if (res[i] + 0) { lc = "\033[35m"; tc = "" }
          else            { lc = "\033[2m";  tc = "\033[2m" }
          printf "%d\t%s\t%s\t%s\t%s\t%s%-*s\033[0m\t\033[2m%4s\033[0m\t\033[34m%-*s\033[0m\t%s%s\033[0m\n", \
            mt[i], id[i], sid[i], cwd[i], res[i], \
            lc, wl, lbl[i], secs2age(age), wd, dir[i], tc, ttl[i]
        }
      }
      function secs2age(s) {
        if (s < 60)    return s "s"
        if (s < 3600)  return int(s / 60) "m"
        if (s < 86400) return int(s / 3600) "h"
        return int(s / 86400) "d"
      }
    ' | sort -t$'\t' -k1,1nr | cut -f2-
}

# ---------------------------------------------------------------------------
# Pickers
# ---------------------------------------------------------------------------

function agents-list() {
  emulate -L zsh

  local hist=0 records=0
  while [[ "$1" == -* ]]; do
    case "$1" in # quoted patterns: this config aliases -h/--help globally
    '--history') hist=1; shift ;;
    '--records') records=1; shift ;;
    '-h' | '--help') print -r -- "usage: agents-list [--history] [--records]"; return 0 ;;
    *) print -u2 "agents-list: unknown option: $1"; return 2 ;;
    esac
  done

  local -a recs
  if (( hist )); then
    recs=(${(f)"$(_agents_history_records)"})
    (( ${#recs} )) || { print -u2 "agents-list: no agent sessions on disk"; return 1 }
  else
    recs=(${(f)"$(_agents_live_records)"})
    (( ${#recs} )) || { print -u2 "agents-list: no agents running in tmux"; return 1 }
  fi

  (( records )) && { print -rl -- "${recs[@]}"; return 0 }
  print -rl -- "${recs[@]}" | cut -f$(( hist ? 5 : 4 ))- | tr '\t' ' '
}

function agents-pick() {
  emulate -L zsh

  local hist=0
  while [[ "$1" == -* ]]; do
    case "$1" in
    '--history') hist=1; shift ;;
    '-h' | '--help') print -r -- "usage: agents-pick [--history]"; return 0 ;;
    *) print -u2 "agents-pick: unknown option: $1"; return 2 ;;
    esac
  done

  if [[ -z "$TMUX" ]]; then
    print -u2 "agents-pick: not inside tmux"
    return 1
  fi
  if ! command -v fzf &>/dev/null; then
    print -u2 "agents-pick: fzf not found; falling back to agents-list"
    if (( hist )); then agents-list --history; else agents-list; fi
    return
  fi

  (( hist )) && { _agents_pick_history; return }
  _agents_pick_live
}

# PREVIEW and KILL are interpolated BARE into --preview/--bind, never via ${(q)}:
# (q) escapes the braces to \{1\} and fzf then passes that through as literal text
# (sessions.zsh). Their empty guards are not paranoia either -- fzf expands {1} to
# '' when nothing is highlighted, and tmux resolves `-t ""` to the CURRENT pane,
# which inside a popup is the pane the key was pressed from.
function _agents_pick_live() {
  emulate -L zsh

  local -a recs
  recs=(${(f)"$(_agents_live_records)"})
  if (( ${#recs} == 0 )); then
    # Non-zero keeps the popup open long enough to read this -- see -EE on the
    # tmux binding (sessions.zsh).
    print -u2 "agents-pick: no agent CLIs running in any tmux pane"
    return 1
  fi

  local _reload_cmd="source ${(q)_AGENTS_ZSH_SRC} && _agents_live_records"
  local RELOAD="reload(zsh -c ${(qq)_reload_cmd})"

  local PREVIEW='
    if [ -z {1} ]; then exit 0; fi
    printf "\033[1;36m%s\033[0m  \033[2m%s\033[0m\n\n" \
      "$(command tmux display-message -p -t {1} "#{session_name}:#{window_index}.#{pane_index}")" \
      "$(command tmux display-message -p -t {1} "#{pane_current_path}")"
    command tmux capture-pane -pe -t {1} |
      grep -v "^[[:space:]]*$" | tail -n "$(( ${FZF_PREVIEW_LINES:-40} - 3 ))"'

  # Signals the leaf of the chain, which cascades up through the launchers and
  # leaves the hosting shell and pane intact. See _agents_leaf.
  local KILL='
    if [ -z {2} ]; then exit 0; fi
    printf "kill agent in %s (pid %s)? [y/N] " {1} {2}
    read -k1 -s ans
    printf "\n"
    case "$ans" in
      y | Y) kill {2} 2>&1 | tail -3; sleep 0.3 ;;
    esac'

  # --with-nth hides fields 1-3 (pane, pid, session id) but keeps them for {n}.
  # --nth indexes the TRANSFORMED line, where 1=label 2=status 3=age 4=loc
  # 5=name 6=dir, so 1,4,5,6 stops a query from matching the status or age
  # columns. --track keeps the cursor where it was across a reload.
  local rec
  rec=$(printf '%s\n' "${recs[@]}" |
    fzf --ansi --tabstop 1 --track \
      --delimiter $'\t' --with-nth '4..' --nth '1,4,5,6' \
      --prompt 'agent> ' \
      --header 'enter=jump  ctrl-x=kill  ctrl-r=refresh  ctrl-l=redraw preview  ctrl-/=preview' \
      --header-first --reverse --no-multi --cycle \
      --preview "$PREVIEW" \
      --preview-window 'right,60%,border-left,wrap' \
      --preview-label ' pane ' \
      --bind 'ctrl-/:toggle-preview' \
      --bind 'ctrl-l:refresh-preview' \
      --bind "ctrl-r:$RELOAD" \
      --bind "ctrl-x:execute($KILL)+$RELOAD")

  # Cancelled or no match. Returning 0 stops -EE from holding the popup open
  # after a deliberate Esc; only the real errors above return non-zero.
  [[ -n "$rec" ]] || return 0

  local pane="${rec%%$'\t'*}"
  [[ -n "$pane" ]] || return 0

  # -t may name a pane to change session, window and pane at once; -Z preserves
  # an existing zoom. That is one call instead of switch-client + select-window
  # + select-pane.
  command tmux switch-client -Z -t "$pane" || {
    print -u2 "agents-pick: could not switch to $pane"
    return 1
  }
}

# Longest path-prefix over pane_current_path, not session_path: a session's own
# path is set once at creation and often points somewhere unrelated to where its
# panes have since moved, and it can be unset entirely. Matches at or above $HOME
# are ignored, since a pane sitting in the home directory says nothing about which
# project a session owns. A tie prefers the session you are already in.
function _agents_session_for() {
  emulate -L zsh
  local cwd="$1" cur
  [[ -n "$cwd" && "$cwd" != '-' ]] || return 1
  cur=$(command tmux display-message -p '#S' 2>/dev/null)

  command tmux list-panes -a -F "#{session_name}	#{pane_current_path}" 2>/dev/null |
    awk -F'\t' -v cwd="$cwd" -v home="$HOME" -v cur="$cur" '
      { p = $2
        if (p == "" || length(p) <= length(home)) next
        if (substr(cwd, 1, length(p)) != p) next
        if (length(p) > mx || (length(p) == mx && $1 == cur)) { mx = length(p); s = $1 }
      }
      END { if (s != "") print s }'
}

function _agents_pick_history() {
  emulate -L zsh

  local -a recs
  recs=(${(f)"$(_agents_history_records)"})
  if (( ${#recs} == 0 )); then
    print -u2 "agents-pick: no agent sessions found on disk"
    return 1
  fi

  local _reload_cmd="source ${(q)_AGENTS_ZSH_SRC} && _agents_history_records"
  local RELOAD="reload(zsh -c ${(qq)_reload_cmd})"

  # {2} is the session id, {1} the CLI id -- the adapter owns how to render a
  # transcript, since only it knows the on-disk format.
  local PREVIEW='
    if [ -z {2} ]; then exit 0; fi
    zsh -c "source '"${(q)_AGENTS_ZSH_SRC}"' && _agents_preview {1} {2} {3}"'

  local rec
  rec=$(printf '%s\n' "${recs[@]}" |
    fzf --ansi --tabstop 1 --track \
      --delimiter $'\t' --with-nth '5..' --nth '1,3,4' \
      --prompt 'session> ' \
      --header 'enter=resume  alt-enter=fork  ctrl-r=refresh  ctrl-/=preview' \
      --header-first --reverse --no-multi --cycle \
      --preview "$PREVIEW" \
      --preview-window 'right,60%,border-left,wrap' \
      --preview-label ' transcript ' \
      --expect=alt-enter \
      --bind 'ctrl-/:toggle-preview' \
      --bind "ctrl-r:$RELOAD")

  local -a lines; lines=("${(@f)rec}")
  local key="${lines[1]}" row="${lines[2]}"
  [[ -n "$row" ]] || return 0

  local -a f; f=("${(@s:	:)row}")
  local id="${f[1]}" sid="${f[2]}" cwd="${f[3]}" resumable="${f[4]}"

  if [[ "$resumable" != 1 ]]; then
    print -u2 "agents-pick: $id is not installed; cannot resume $sid"
    return 1
  fi

  if (( ! ${+functions[_agents_${id}_resume]} )); then
    print -u2 "agents-pick: $id has no resume support; see ${_AGENTS_DIR}/$id.zsh"
    return 1
  fi

  local cmd
  cmd=$(_agents_${id}_resume "$sid" "$cwd") || {
    print -u2 "agents-pick: $id: could not build a resume command"
    return 1
  }
  [[ "$key" == alt-enter ]] && (( ${+functions[_agents_${id}_fork_flag]} )) &&
    cmd+=" $(_agents_${id}_fork_flag)"

  # Several transcripts point at scratch directories that no longer exist, and
  # new-window fails outright on a missing -c.
  local start="$cwd"
  [[ -d "$start" ]] || {
    print -u2 "agents-pick: $cwd no longer exists; starting in $HOME"
    start="$HOME"
  }

  local target
  target=$(_agents_session_for "$start")
  if [[ -n "$target" && "$target" != "$(command tmux display-message -p '#S')" ]]; then
    command tmux switch-client -t "=$target" || return 1
  fi

  # `zsh -c`, not `zsh -ic`: _agents_bin already resolved an absolute path, so an
  # interactive shell would add nothing but its own startup cost. The
  # hold-on-failure prompt is the repos.zsh idiom -- without it the window closes
  # before a bad session id or a missing binary can be read.
  local hold="|| { print -u2 \"resume failed: $id $sid\"; read -k1 -s }"
  command tmux new-window ${target:+-t "=$target"} -c "$start" \
    "zsh -c ${(qq)${:-$cmd $hold}}" || {
    print -u2 "agents-pick: could not open a window for $sid"
    return 1
  }
}

# Transcript preview, delegated to the adapter. Falls back to a plain tail so a
# CLI with no preview hook is still browsable.
function _agents_preview() {
  emulate -L zsh
  _agents_load
  local id="$1" sid="$2" cwd="$3"

  printf '\033[1;36m%s\033[0m  \033[2m%s\033[0m\n\n' "$sid" "${cwd/#$HOME/~}"
  if (( ${+functions[_agents_${id}_preview]} )); then
    _agents_${id}_preview "$sid" "$cwd"
  else
    print -r -- "(no preview available for $id)"
  fi
}
