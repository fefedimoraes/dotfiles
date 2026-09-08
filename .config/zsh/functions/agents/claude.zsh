# Claude Code. https://code.claude.com

_agents_register claude glyph='󰚩' label='claude' bin='claude' comms='claude'

: ${CLAUDE_CONFIG_DIR:=$HOME/.claude}

# Decoration only: this registry can be absent or empty while agents are running,
# so it may add detail to rows the process scan found but must never be the source
# of what exists. Entries also survive process exit, hence the liveness check.
# `.tmux` is "<session>:@<window-id>.%<pane-id>"; the pid is the leaf of the
# process chain, which is what agents.zsh keys on.
function _agents_claude_enrich() {
  emulate -L zsh
  local -a files=("$CLAUDE_CONFIG_DIR"/sessions/*.json(N))
  (( $#files )) || return 0

  local pid pane st name sid since   # not "status": read-only in zsh
  command jq -r '
    select(.kind == "interactive" and .tmux != null and .tmux != "")
    | [ .pid,
        (.tmux | sub(".*\\."; "")),
        (.status // "-"),
        (.name // "-"),
        (.sessionId // "-"),
        (((.updatedAt // .startedAt // 0) / 1000) | floor) ]
    | @tsv' -- "${files[@]}" 2>/dev/null |
    while IFS=$'\t' read -r pid pane st name sid since; do
      [[ -n "$pane" ]] || continue
      kill -0 "$pid" 2>/dev/null || continue
      printf 'E\t%s\t%s\t%s\t%s\t%s\n' "$pane" "$st" "$name" "$sid" "$since"
    done
}

# Titles moved between releases and there are no `summary` records any more, so
# fall through every naming signal in order of usefulness.
function _agents_claude_parse() {
  emulate -L zsh
  (( $# )) || return 0

  command jq -r '
    select(has("aiTitle") or has("agentName") or has("slug")
           or has("lastPrompt") or has("cwd"))
    | [ input_filename,
        (.aiTitle // ""), (.agentName // ""), (.slug // ""),
        (.lastPrompt // ""), (.cwd // "") ]
    | @tsv' -- "$@" 2>/dev/null |
    awk -F'\t' '
      { f = $1; seen[f] = 1
        if ($2 != "") ai[f] = $2
        if ($3 != "") an[f] = $3
        if ($4 != "") sl[f] = $4
        if ($5 != "") lp[f] = $5
        if ($6 != "") cw[f] = $6 }
      END {
        for (f in seen) {
          t = ai[f]
          if (t == "") t = an[f]
          if (t == "") t = sl[f]
          if (t == "") t = lp[f]
          if (t == "") t = "-"
          # lastPrompt is raw user text. @tsv escapes a real tab to the two
          # characters \t, so both forms have to go or the field count shifts.
          gsub(/\\[tnr]/, " ", t); gsub(/[\t\r\n]+/, " ", t)
          if (length(t) > 80) t = substr(t, 1, 79) "…"
          c = (cw[f] == "") ? "-" : cw[f]
          printf "%s\t%s\t%s\n", f, c, t
        }
      }'
}

# Emits: session_id  cwd  mtime  title
#
# One level of globbing on purpose: <project>/<sessionId>.jsonl is a resumable
# session, while <project>/<sessionId>/subagents/*.jsonl are subagent transcripts
# that cannot be resumed. The basename is the session id, so it never has to be
# parsed out of the JSON.
#
# Parsing every transcript is far too slow to pay on each keypress, so the cache is
# keyed on each file's mtime and only changed transcripts are re-parsed -- usually
# none or one. zstat is a builtin, so stat'ing the whole set costs no forks. mtime
# doubles as the session's age, which is why no timestamp is read from the JSON.
function _agents_claude_history() {
  emulate -L zsh
  zmodload -F zsh/stat b:zstat 2>/dev/null || return 0

  local -a files
  files=("$CLAUDE_CONFIG_DIR"/projects/*/*.jsonl(N))
  (( $#files )) || return 0

  local cache="${TMPDIR:-/tmp}/agents-hist-claude.$UID"
  local cur="${TMPDIR:-/tmp}/agents-hist-cur.$$"
  local stale="${TMPDIR:-/tmp}/agents-hist-stale.$$"
  local merged="${TMPDIR:-/tmp}/agents-hist-new.$$"
  local tmpcache="$cache.$$"

  {
    local -a mtimes
    zstat -A mtimes +mtime -- "${files[@]}" 2>/dev/null || return 0

    local i
    for (( i = 1; i <= $#files; i++ )); do
      printf '%s\t%s\t%s\n' "${files[i]:t:r}" "${mtimes[i]}" "${files[i]}"
    done >|"$cur"

    [[ -f "$cache" ]] || : >|"$cache"
    : >|"$stale"

    # FILENAME, not NR == FNR: on a cold run the cache is empty, and NR == FNR
    # then stays true for every line of the SECOND file, so nothing is emitted and
    # nothing is marked stale.
    awk -F'\t' -v stale="$stale" -v cachefile="$cache" '
      FILENAME == cachefile { m[$2] = $1; c[$2] = $3; t[$2] = $4; next }
      { if ($1 in m && m[$1] == $2) printf "%s\t%s\t%s\t%s\n", $2, $1, c[$1], t[$1]
        else print $3 > stale }
    ' "$cache" "$cur" >|"$merged"

    if [[ -s "$stale" ]]; then
      local -a todo
      todo=(${(f)"$(<$stale)"})
      _agents_claude_parse "${todo[@]}" |
        awk -F'\t' -v curfile="$cur" '
          FILENAME == curfile { mt[$3] = $2; sid[$3] = $1; next }
          $1 in mt { printf "%s\t%s\t%s\t%s\n", mt[$1], sid[$1], $2, $3 }
        ' "$cur" - >>"$merged"
    fi

    sort -t$'\t' -k1,1nr "$merged" >|"$tmpcache" &&
      command mv -f -- "$tmpcache" "$cache"

    awk -F'\t' '{ printf "%s\t%s\t%s\t%s\n", $2, $3, $1, $4 }' "$cache"
  } always {
    command rm -f -- "$cur" "$stale" "$merged" "$tmpcache"
  }
}

function _agents_claude_preview() {
  emulate -L zsh
  local -a f=("$CLAUDE_CONFIG_DIR"/projects/*/"$1".jsonl(N))
  (( $#f )) || { print -r -- '(transcript not found)'; return 0 }

  # message.content is a plain string for typed prompts but an array of blocks
  # for tool returns and synthetic turns, so both shapes have to be handled.
  command jq -r '
    if .type == "user" then
      (if (.message.content | type) == "string" then .message.content
       else (.message.content // [] | map(select(.type == "text") | .text) | join("\n")) end)
      | select(. != null and . != "")
      | "\u001b[33m❯\u001b[0m " + .
    elif .type == "assistant" then
      (.message.content // [] | map(select(.type == "text") | .text) | join("\n"))
      | select(. != "")
    else empty end' -- "${f[1]}" 2>/dev/null |
    grep -v '^[[:space:]]*$' | tail -n 300
}

function _agents_claude_resume() {
  emulate -L zsh
  local bin
  bin=$(_agents_bin claude) || return 1
  print -r -- "${(q)bin} --resume ${(q)1}"
}

function _agents_claude_fork_flag() { print -r -- '--fork-session' }
