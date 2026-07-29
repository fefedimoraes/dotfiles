function mth() {
  local millis=${1-}

  if [ -z "$millis" ]; then
    script="${0##*/}"
    echo "Returns the ISO date for the provided milliseconds since epoch"
    echo "usage: $script <milliseconds-since-epoch>"
    echo "example: $script 1620418406902"
    return
  fi

  local float=$(echo "scale=3; $millis / 1000" | bc)

  local command="date"
  # add for MacOS portability, requires coreutils to be installed via homebrew
  if [ ! -z "$(which gdate)" ]; then
    command="gdate"
  fi

  $command -u -d "@$float" --iso-8601='seconds'
}

function nowtos() {
  local to=${1-}

  if [ -z "$to" ]; then
    script="${0##*/}"
    echo "Returns the difference between now to the provided date in seconds"
    echo "usage: $script <timestamp>"
    echo "example: $script 2025-09-13T01:02:03.456PDT"
    return
  fi

  local diff=$(($(gdate +%s -d $to) - $(date +%s)))
  echo $diff
}

function nowplustos() {
  local offset=${1-}

  if [ -z "$offset" ]; then
    script="${0##*/}"
    echo "Returns the difference between now to the provided offset in seconds"
    echo "usage: $script <offset>"
    echo "example: $script \"5 hours 30 min\""
    return
  fi

  local diff=$(($(gdate +%s -d "now + $offset") - $(date +%s)))
  echo $diff
}
