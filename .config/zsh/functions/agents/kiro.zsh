# Kiro CLI (formerly Amazon Q). History and preview only, no live decoration: the
# generic process scan already finds a running instance. Where the binary is not
# installed, the core lists its sessions as unresumable rather than hiding them.

_agents_register kiro glyph='󰚩' label='kiro' bin='kiro-cli' comms='kiro-cli|kiro'

: ${KIRO_CONFIG_DIR:=$HOME/.kiro}

# Emits: session_id  cwd  mtime  title
#
# session_id, cwd, title and updated_at are all first-class top-level keys, so one
# jq over every file is enough and no mtime cache is needed. `.title` is the
# verbatim first prompt rather than a generated summary. These files embed the
# whole conversation, so only top-level keys are read.
function _agents_kiro_history() {
  emulate -L zsh
  local -a files=("$KIRO_CONFIG_DIR"/sessions/cli/*.json(N))
  (( $#files )) || return 0

  command jq -r '
    select(.session_id != null)
    | [ .session_id,
        (.cwd // "-"),
        # fromdateiso8601 rejects fractional seconds, which these timestamps have.
        (((.updated_at // .created_at // "") | sub("\\.[0-9]+"; ""))
          | if . == "" then 0 else (try fromdateiso8601 catch 0) end),
        ((.title // "-") | gsub("[\\t\\r\\n]+"; " ") | .[0:80]) ]
    | @tsv' -- "${files[@]}" 2>/dev/null
}

function _agents_kiro_preview() {
  emulate -L zsh
  local f="$KIRO_CONFIG_DIR/sessions/cli/$1.jsonl"
  [[ -r "$f" ]] || { print -r -- '(transcript not found)'; return 0 }

  command jq -r '
    if .kind == "Prompt" then
      ((.data.content // [] | map(select(.kind == "text") | .data) | join("\n"))
        | select(. != "") | "\u001b[33m❯\u001b[0m " + .)
    elif .kind == "AssistantMessage" then
      ((.data.content // [] | map(select(.kind == "text") | .data) | join("\n"))
        | select(. != ""))
    else empty end' -- "$f" 2>/dev/null |
    grep -v '^[[:space:]]*$' | tail -n 300
}
