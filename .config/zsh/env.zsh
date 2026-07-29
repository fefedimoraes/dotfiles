# Environment and PATH. Must load first -- zinit, starship, zoxide, fzf, eza and
# bat are all only on PATH after brew shellenv runs.

# Set PATH, MANPATH, etc., for Homebrew
export HOMEBREW_NO_AUTO_UPDATE=1 # Do not update on install

[ -f /apollo/env/envImprovement/var/zshrc ] && source /apollo/env/envImprovement/var/zshrc
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"                           # Apple Silicon
[ -f /usr/local/Homebrew/bin/brew ] && eval "$(/usr/local/Homebrew/bin/brew shellenv)"               # Apple Intel
[ -f /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" # Linux
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"                                                    # Add Homebrew OpenJDK to path

# Add sbin to path
export PATH="/usr/local/sbin:$PATH"
export EDITOR='nvim'
