# Zinit plugin manager and plugins. Must load before completion.zsh, which runs
# compinit against the fpath entries the plugins below add.

# Install Zinit plugin manager
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Install Tmux plugin manager
# Not vestigial despite .config/tmux/plugins: tmux.conf runs ~/.tmux/plugins/tpm/tpm
TPM_HOME="${HOME}/.tmux/plugins/tpm"
[ ! -d $TPM_HOME ] && mkdir -p "$(dirname $TPM_HOME)"
[ ! -d $TPM_HOME/.git ] && git clone https://github.com/tmux-plugins/tpm "$TPM_HOME"

# Install zsh plugins
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting # keep last, per the plugin's docs

# Add snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::command-not-found
zinit snippet OMZP::tmux
