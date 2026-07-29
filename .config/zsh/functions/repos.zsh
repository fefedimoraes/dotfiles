# Shared record producer for repos-status / repos-pick.
# Emits one TAB-delimited record per repo found in $1 (default $PWD):
#   abs_path <TAB> prefix <TAB> padded_name <TAB> details
# Tab-delimited (not space-aligned) so fzf --nth can target the name field
# reliably even when a glyph is missing or a detached HEAD adds spaces.
# NOTE: never name a local "path" here -- in zsh it is tied to $PATH, which
# would blank PATH for the whole function and make every git call fail.
function _repos_status_records() {
  emulate -L zsh

  # Glyphs as \u escapes so formatters/encodings cannot strip them.
  local g_clean=$'' g_dirty=$'' g_branch=$''
  local g_ahead=$'' g_behind=$'' g_detached=$''
  local g_repo=$''

  local root="${1:-$PWD}" d name width=0
  local -a repos names
  for d in "$root"/*/(N); do
    [ -d "$d/.git" ] || continue
    name="${${d%/}:t}"
    repos+=("${d%/}") # strip trailing / so lazygit -p gets a clean path
    names+=("$name")
    ((${#name} > width)) && width=${#name}
  done
  ((${#repos})) || return 1

  local i branch ab behind ahead sync dirty pfx det
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
      printf -v pfx "\033[32m%s\033[0m %s" "$g_clean" "$g_repo"
      printf -v det " %s %-16s %s" "$g_branch" "$branch" "$sync"
    else
      printf -v pfx "\033[33m%s\033[0m %s" "$g_dirty" "$g_repo"
      printf -v det " %s %-16s %s \033[33m(%s)\033[0m" \
        "$g_branch" "$branch" "$sync" "$dirty"
    fi

    printf "%s\t%s\t%-*s\t%s\n" "$d" "$pfx" "$width" "$name" "$det"
  done
}

# Show git status of every immediate subdirectory that is a git repo.
# Requires a Nerd Font in the terminal for the glyphs to render.
# Usage: repos-status [-f|--files] [root-dir]
#   * With an arg           -> scans that directory.
#   * No arg, inside a repo -> scans the repo's siblings (its parent dir).
#   * No arg, not in a repo -> scans the current directory.
#   * -f / --files          -> also list changed files, marking staged vs unstaged.
# See also: repos-pick (fuzzy-pick a repo and open it in lazygit).
function repos-status() {
  emulate -L zsh

  local g_staged=$''    # nf-fa-plus_circle        (staged / index)
  local g_unstaged=$''  # nf-fa-exclamation_circle (unstaged / worktree)
  local g_untracked=$'' # nf-fa-question_circle    (untracked)

  local files=0 records=0
  while [[ "$1" == -* ]]; do
    # Patterns are quoted: this file defines global aliases for -h/--help,
    # which would otherwise expand inside these patterns and break parsing.
    case "$1" in
    '-f' | '--files') files=1; shift ;;
    '--records') records=1; shift ;; # internal: raw records for repos-pick
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

  local -a recs
  recs=(${(f)"$(_repos_status_records "$root")"})
  if ((${#recs} == 0)); then
    print -u2 "repos-status: no git repositories found in $root"
    return 1
  fi
  ((records)) && { print -rl -- "${recs[@]}"; return 0; }

  local rec rpath pfx rname det line x y relpath sm um
  local -a st
  for rec in "${recs[@]}"; do
    IFS=$'\t' read -r rpath pfx rname det <<<"$rec"
    # det starts with one space; the extra literal space here reproduces the
    # two-column gap that fzf gets from the record's tab at --tabstop 1.
    printf "%s %s %s\n" "$pfx" "$rname" "$det"

    ((files)) || continue

    # Porcelain v1 status: col 1 = index (staged), col 2 = worktree (unstaged).
    st=(${(f)"$(git -C "$rpath" -c core.quotePath=false status --porcelain 2>/dev/null)"})
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

# Fuzzy-pick a sibling git repo by NAME and open it in lazygit.
# Enter opens lazygit; quitting lazygit returns here with status refreshed.
# Usage: repos-pick [root-dir]   (root resolution matches repos-status)
function repos-pick() {
  emulate -L zsh

  if ! command -v fzf &>/dev/null; then
    print -u2 "repos-pick: fzf not found; falling back to repos-status"
    repos-status "$@"
    return
  fi

  local root
  if [ -n "$1" ]; then
    root="$1"
  else
    local top
    top=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$top" ]; then root="${top:h}"; else root="$PWD"; fi
  fi

  # fzf runs child commands with `$SHELL -c` (non-interactive), which does NOT
  # source .zshrc -- so reload must go through `zsh -ic` to see repos-status.
  # 2>/dev/null drops the harmless "can't change option: zle" startup noise.
  local RELOAD="reload(zsh -ic 'repos-status --records ${(q)root}' 2>/dev/null)"
  local PREVIEW='git -C {1} -c color.status=always status --short --branch
    echo
    git -C {1} --no-pager log --color=always --oneline --graph --decorate -n 15'

  # --with-nth hides field 1 (the path) but keeps it available to {1}.
  # --nth indexes the TRANSFORMED line, so --nth 2 is the name (record field 3).
  # {1} is expanded shell-quoted by fzf; do not add quotes around it.
  _repos_status_records "$root" |
    fzf --ansi --tabstop 1 \
      --delimiter $'\t' --with-nth '2..' --nth 2 \
      --prompt 'repo> ' \
      --header "${root}   enter=lazygit  ctrl-r=refresh  ctrl-/=preview" \
      --header-first --reverse --no-multi --cycle \
      --preview "$PREVIEW" --preview-window 'right,55%,border-left' \
      --bind 'ctrl-/:toggle-preview' \
      --bind "ctrl-r:$RELOAD" \
      --bind "enter:execute(lazygit -p {1})+$RELOAD"
}
