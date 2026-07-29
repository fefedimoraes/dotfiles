# .dotfiles

This repository contains `dotfiles` configuration files for multiple applications, including terminal emulators, shells, tmux, nvim, and other CLI applications.

## Zsh layout

`.zshrc` is a thin loader; the actual configuration lives in modules under
`.config/zsh/`:

| File               | Contents                                             |
| ------------------ | ---------------------------------------------------- |
| `env.zsh`          | Homebrew bootstrap, `PATH`, `EDITOR`                 |
| `tmux.zsh`         | Auto-attach to tmux                                  |
| `plugins.zsh`      | Zinit and tpm bootstrap, plugins, Oh My Zsh snippets |
| `completion.zsh`   | `compinit`, completion and `fzf-tab` styles          |
| `options.zsh`      | History configuration and `setopt`s                  |
| `keybindings.zsh`  | `edit-command-line` widget and `bindkey`s            |
| `aliases.zsh`      | All aliases, including the global ones               |
| `functions/*.zsh`  | One file per group of functions, auto-sourced        |
| `integrations.zsh` | nvm (deferred), fzf, zoxide, starship                |
| `amzn.zsh`         | Amazon-internal config; sourced only if present      |

The load order in `.zshrc` is deliberate — for example `compinit` has to run
after `zsh-completions` is loaded, and `aliases.zsh` has to precede `functions/`
because the global `-h`/`--help` aliases are expanded while the function bodies
are parsed. Each module documents its own constraints at the top; read those
before reordering.

Drop a new file into `.config/zsh/functions/` to add functions — no re-stow and
no loader change needed, since the directory is a single folded symlink and the
files are picked up by a glob.

## After checking out

```bash
# Install base Brewfile
brew bundle install --file=Brewfile

# If installing on a personal computer
brew bundle install --file=Brewfile.personal

# Link configuration files to home directory
stow .

# Rebuild bat cache
bat cache --build

# Start skhd
skhd --start-service

# Start JankyBorders
brew services start borders
```

## Other commands

### Install Tmux plug-ins

```bash
<C-s> I
```

### Unlink configuration files

```bash
stow -D .
```
