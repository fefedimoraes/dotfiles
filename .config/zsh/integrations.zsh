# Shell integrations. Loaded last so zoxide's chpwd hook and starship's precmd
# hook land at the end of the hook arrays, which is what both tools expect.

# NVM -- deferred. Sourcing nvm.sh costs ~1.2s and defines ~109 functions, but
# activates nothing here (no default version is set, and node comes from
# Homebrew), so paying it on every shell is pure waste. These shims replace
# themselves with the real nvm on first call.
export NVM_DIR="$HOME/.nvm"

if [ -s "$NVM_DIR/nvm.sh" ]; then
  function _nvm_load() {
    unfunction nvm node npm npx _nvm_load 2>/dev/null
    source "$NVM_DIR/nvm.sh"                                            # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion" # This loads nvm bash_completion
  }

  for _nvm_cmd in nvm node npm npx; do
    eval "function ${_nvm_cmd}() { _nvm_load; ${_nvm_cmd} \"\$@\"; }"
  done
  unset _nvm_cmd
fi

eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"
