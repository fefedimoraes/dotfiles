# Amazon-internal config. Sourced only if this file exists, which replaces the
# old `[ "$(whoami)" = "moraesf" ]` guard -- that check was a no-op here, since
# the same username is used on personal machines. Mirrors the Brewfile /
# Brewfile.amzn split: drop this file on a machine that is not a work machine.

# Added by AIM CLI
export PATH="$HOME/.aim/mcp-servers:$PATH"
export PATH="${HOME}/.pyenv/shims:${PATH}"
export PATH=$PATH:$HOME/.toolbox/bin
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
export DEV_DESKTOP=$USER.aka.corp.amazon.com
export SOCK_FILE=/tmp/ssh-socket-2009-$DEV_DESKTOP

# Aliases
alias startodin='ssh -L 2009:localhost:2009 $DEV_DESKTOP -N -f -T -M -S $SOCK_FILE -o ExitOnForwardFailure=yes'
alias stopodin='ssh -S $SOCK_FILE -O exit $DEV_DESKTOP'
alias checkodin='ssh -S $SOCK_FILE -O check $DEV_DESKTOP'

alias amazon-login="mwinit -f -s"
alias otp-amazon-login="mwinit -o -s"

alias bb=brazil-build
alias cbb='brazil-build clean && brazil-build'
alias bba='brazil-build apollo-pkg'
alias bre='brazil-runtime-exec'
alias brc='brazil-recursive-cmd'
alias bws='brazil ws'
alias bwsuse='bws use --gitMode -p'
alias bwscreate='bws create -n'
alias brc=brazil-recursive-cmd
alias bbr='brc brazil-build'
alias bball='brc --allPackages'
alias bbb='brc --allPackages brazil-build'
alias bbra='bbr apollo-pkg'
alias bbrst='brc brazil-build build'
alias bbbst='brc --allPackages brazil-build build'
alias bwc='brazil-workplace-clean'
alias bsps='brazil setup platform-support'

alias bpc='brazil-package-cache stop; brazil-package-cache start'

alias mossy='/apollo/env/Mossy/bin/mossy'

# Custom Functions
function ada-login() {
  ada credentials update --account=$1 --provider=conduit --role=IibsAdminAccess-DO-NOT-DELETE --once
}

function ada-login-ro() {
  ada credentials update --account=$1 --provider=conduit --role=IibsAdminAccess-DO-NOT-DELETE --once --conduit-read-only
}

function brazil-workplace-clean() {
  for WORKSPACE in *; do
    if [ -d "${WORKSPACE}" ] && [ -f "${WORKSPACE}/packageInfo" ]; then
      pushd "${WORKSPACE}" >/dev/null
      echo "Cleaning ${WORKSPACE}..."
      bws clean
      popd >/dev/null
    fi
  done
}

function startportforward() {
  ssh -L $1:localhost:$1 $DEV_DESKTOP -N -f -T -M -S /tmp/ssh-socket-$1-$DEV_DESKTOP -o ExitOnForwardFailure=yes
}

function stopportforward() {
  ssh -S /tmp/ssh-socket-$1-$DEV_DESKTOP -O exit $DEV_DESKTOP
}

function checkportforward() {
  ssh -S /tmp/ssh-socket-$1-$DEV_DESKTOP -O check $DEV_DESKTOP
}
