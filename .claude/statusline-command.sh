#!/usr/bin/env bash

# Claude Code status line script — declarative multi-line layout
input=$(cat)

# --- Catppuccin Macchiato palette (24-bit) ---
export ESC=$'\033'
export C_RESET="${ESC}[0m"
export C_ROSEWATER="${ESC}[38;2;244;219;214m"
export C_FLAMINGO="${ESC}[38;2;240;198;198m"
export C_PINK="${ESC}[38;2;245;189;230m"
export C_MAUVE="${ESC}[38;2;198;160;246m"
export C_RED="${ESC}[38;2;237;135;150m"
export C_MAROON="${ESC}[38;2;238;153;160m"
export C_PEACH="${ESC}[38;2;245;169;127m"
export C_YELLOW="${ESC}[38;2;238;212;159m"
export C_GREEN="${ESC}[38;2;166;218;149m"
export C_TEAL="${ESC}[38;2;139;213;202m"
export C_SKY="${ESC}[38;2;145;215;227m"
export C_SAPPHIRE="${ESC}[38;2;125;196;228m"
export C_BLUE="${ESC}[38;2;138;173;244m"
export C_LAVENDER="${ESC}[38;2;183;189;248m"
export C_TEXT="${ESC}[38;2;202;211;245m"
export C_SUBTEXT1="${ESC}[38;2;184;192;224m"
export C_SUBTEXT0="${ESC}[38;2;165;173;203m"
export C_OVERLAY2="${ESC}[38;2;147;154;183m"
export C_OVERLAY1="${ESC}[38;2;128;135;162m"
export C_OVERLAY0="${ESC}[38;2;110;115;141m"
export C_SURFACE2="${ESC}[38;2;91;96;120m"
export C_SURFACE1="${ESC}[38;2;73;77;100m"
export C_SURFACE0="${ESC}[38;2;54;58;79m"
export C_BASE="${ESC}[38;2;36;39;58m"
export C_MANTLE="${ESC}[38;2;30;32;48m"
export C_CRUST="${ESC}[38;2;24;25;38m"

BOLD="${ESC}[1m"
ITALIC="${ESC}[3m"
PIPE="${C_OVERLAY2} | ${C_RESET}"

# --- Functions ---
fmt_num() {
  local n="$1"
  if [ -z "$n" ] || [ "$n" = "null" ]; then
    echo "—"
    return
  fi
  if [ "$n" -ge 1000000 ] 2>/dev/null; then
    printf "%.1fM" "$(echo "scale=1; $n/1000000" | bc)"
  elif [ "$n" -ge 1000 ] 2>/dev/null; then
    printf "%.1fk" "$(echo "scale=1; $n/1000" | bc)"
  else
    echo "$n"
  fi
}

fmt_pct() {
  local pct="$1"
  if [ -z "$pct" ]; then
    echo "—"
  else
    printf "%.0f%%" "$pct"
  fi
}

fmt_ctx() {
  local pct="$1" size="$2"
  if [ -z "$pct" ] && [ -z "$size" ]; then
    echo "—"
    return
  fi
  local pct_fmt size_fmt
  pct_fmt=$(fmt_pct "$pct")
  size_fmt=$(fmt_num "$size")
  echo "${pct_fmt} of ${size_fmt}"
}

fmt_elapsed() {
  local start="$1"
  if [ -z "$start" ]; then
    echo "—"
    return
  fi
  local now elapsed
  now=$(date +%s)
  elapsed=$((now - start))
  if [ "$elapsed" -ge 3600 ]; then
    printf "%dh%02dm" $((elapsed / 3600)) $(((elapsed % 3600) / 60))
  elif [ "$elapsed" -ge 60 ]; then
    printf "%dm%02ds" $((elapsed / 60)) $((elapsed % 60))
  else
    printf "%ds" "$elapsed"
  fi
}

fmt_duration_ms() {
  local ms="$1"
  if [ -z "$ms" ] || [ "$ms" = "null" ]; then
    echo "—"
    return
  fi
  local secs=$((ms / 1000))
  if [ "$secs" -ge 3600 ]; then
    printf "%dh%02dm" $((secs / 3600)) $(((secs % 3600) / 60))
  elif [ "$secs" -ge 60 ]; then
    printf "%dm%02ds" $((secs / 60)) $((secs % 60))
  else
    printf "%ds" "$secs"
  fi
}

fmt_cost() {
  local cost="$1"
  if [ -z "$cost" ] || [ "$cost" = "null" ]; then
    echo "—"
    return
  fi
  printf "\$%.2f" "$cost"
}

fmt_tokens() {
  local current="$1" total="$2"
  if [ -z "$current" ] && [ -z "$total" ]; then
    echo "—"
    return
  fi
  local cur_fmt tot_fmt
  cur_fmt=$(fmt_num "$current")
  tot_fmt=$(fmt_num "$total")
  echo "${cur_fmt}/${tot_fmt}"
}

fmt_lines_changed() {
  local added="$1" removed="$2"
  if [ -z "$added" ] && [ -z "$removed" ]; then
    return
  fi
  echo -n "${ITALIC}${C_GREEN}+${added:-0}${C_RESET}/${ITALIC}${C_RED}-${removed:-0}${C_RESET}"
}

fmt_session_id() {
  local sid="$1"
  if [ -z "$sid" ]; then
    return
  fi
  echo "${sid:0:8}"
}

fmt_cwd() {
  local path="$1"
  if [ -z "$path" ]; then
    return
  fi
  path="${path/#$HOME/~}"
  if [ "$(echo "$path" | tr '/' '\n' | wc -l)" -gt 4 ]; then
    echo "…/$(echo "$path" | rev | cut -d'/' -f1-3 | rev)"
  else
    echo "$path"
  fi
}

fmt_version() {
  local ver="$1"
  if [ -z "$ver" ]; then
    return
  fi
  echo "v${ver}"
}

get_session_start_epoch() {
  local sid="$1"
  if [ -z "$sid" ]; then
    return
  fi
  local session_file="/tmp/claude-session-${sid}"
  if [ -f "$session_file" ]; then
    command cat "$session_file"
  else
    local epoch
    epoch=$(date +%s)
    echo "$epoch" >"$session_file"
    echo "$epoch"
  fi
}

get_git_branch() {
  local dir="$1"
  GIT_OPTIONAL_LOCKS=0 git -C "${dir:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null
}

render_widget() {
  local color="$1" label="$2" value="$3"
  if [ -z "$value" ]; then
    return 1
  fi
  if [ -n "$label" ] && [ -n "$color" ]; then
    echo -n "${BOLD}${C_SUBTEXT0}${label}:${C_RESET} ${ITALIC}${color}${value}${C_RESET}"
  elif [ -n "$label" ]; then
    echo -n "${BOLD}${C_SUBTEXT0}${label}:${C_RESET} ${value}"
  elif [ -n "$color" ]; then
    echo -n "${ITALIC}${color}${value}${C_RESET}"
  else
    echo -n "${value}"
  fi
}

render_line() {
  local first=1
  while [ $# -gt 0 ]; do
    local color="$1" label="$2" value="$3"
    shift 3
    local widget
    widget=$(render_widget "$color" "$label" "$value") || continue
    if [ "$first" -eq 1 ]; then
      first=0
    else
      echo -n "${PIPE}"
    fi
    echo -n "$widget"
  done
}

# --- Parse input fields ---
in_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
out_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
cache_tokens=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // empty')
cur_in_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
cur_out_tokens=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
model=$(echo "$input" | jq -r '.model.display_name // ""')
version=$(echo "$input" | jq -r '.version // ""')
session_id=$(echo "$input" | jq -r '.session_id // empty')
session_name=$(echo "$input" | jq -r '.session_name // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
api_duration_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // empty')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')

# --- Derived values ---
session_start_epoch=$(get_session_start_epoch "$session_id")
session_clock=$(fmt_elapsed "$session_start_epoch")
session_id_short=$(fmt_session_id "$session_id")
git_branch=$(get_git_branch "$cwd")
cwd_fmt=$(fmt_cwd "$cwd")
version_fmt=$(fmt_version "$version")
in_fmt=$(fmt_tokens "$cur_in_tokens" "$in_tokens")
out_fmt=$(fmt_tokens "$cur_out_tokens" "$out_tokens")
cache_fmt=$(fmt_num "$cache_tokens")
ctx_fmt=$(fmt_ctx "$used_pct" "$ctx_size")
cost_fmt=$(fmt_cost "$cost_usd")
api_duration_fmt=$(fmt_duration_ms "$api_duration_ms")
lines_fmt=$(fmt_lines_changed "$lines_added" "$lines_removed")

# --- Layout: each line is an array of [color, label, value] widgets ---
render_line \
  "$C_ROSEWATER" "" "$session_name" \
  "$C_SAPPHIRE" "" "$session_id_short" \
  "$C_FLAMINGO" "󰔛" "$session_clock" \
  "$C_YELLOW" "" "$cost_fmt" \
  "$C_LAVENDER" "" "$model" \
  "$C_SKY" "" "$version_fmt"
echo

render_line \
  "$C_GREEN" "󰜮" "$in_fmt" \
  "$C_RED" "󰜷" "$out_fmt" \
  "$C_MAUVE" "" "$cache_fmt" \
  "$C_TEAL" "󰊕" "$ctx_fmt" \
  "$C_FLAMINGO" "󰾆" "$api_duration_fmt"
echo

render_line \
  "$C_SAPPHIRE" "" "$git_branch" \
  "" "" "$lines_fmt" \
  "$C_LAVENDER" "󱐋" "$effort"
echo

render_line \
  "$C_PINK" "" "$cwd_fmt"
echo
