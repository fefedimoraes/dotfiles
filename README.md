# .dotfiles

This repository contains `dotfiles` configuration files for multiple applications, including terminal emulators, shells, tmux, nvim, and other CLI applications.

## CLI tools

The CLI/TUI tools this repo configures (most installed via `Brewfile`), roughly ordered from drop-in / beginner-friendly at the top to heavily-customized high-investment at the bottom.

| Tool         | What it does                                                                                               | Links                                                                                       |
| ------------ | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| **zoxide**   | Smarter `cd` that learns your most-used directories and jumps by frequency. Wired to replace `cd`.         | [github](https://github.com/ajeetdsouza/zoxide)                                             |
| **eza**      | Modern `ls` replacement with icons, colors, and a tree view. Aliased to `ls`/`ll`/`lt`.                    | [site](https://eza.rocks/) · [github](https://github.com/eza-community/eza)                 |
| **bat**      | `cat` with syntax highlighting and Git integration; also used as the man pager and `--help` pager.         | [github](https://github.com/sharkdp/bat)                                                    |
| **fzf**      | General-purpose fuzzy finder; powers tab completion (fzf-tab) and custom file/repo/session pickers.        | [github](https://github.com/junegunn/fzf)                                                   |
| **yazi**     | Blazing-fast terminal file manager with image previews. Launched via the `y` function (cd-on-exit).        | [site](https://yazi-rs.github.io/) · [github](https://github.com/sxyazi/yazi)               |
| **btop**     | Resource monitor (CPU, memory, network, processes) with a rich TUI. Aliased to `t`.                        | [github](https://github.com/aristocratos/btop)                                              |
| **lazygit**  | Terminal UI for Git — stage, commit, branch, and rebase interactively. Aliased to `lg`.                    | [github](https://github.com/jesseduffield/lazygit)                                          |
| **gh**       | GitHub's official CLI for PRs, issues, and repos from the terminal.                                        | [site](https://cli.github.com/) · [github](https://github.com/cli/cli)                      |
| **delta**    | Syntax-highlighting pager for Git diffs; wired in as the pager in `.gitconfig`.                            | [site](https://dandavison.github.io/delta/) · [github](https://github.com/dandavison/delta) |
| **starship** | Fast, cross-shell prompt; here fully themed (Catppuccin Macchiato) with per-language modules.              | [site](https://starship.rs/) · [github](https://github.com/starship/starship)               |
| **git**      | Distributed version control; configured with delta, conditional Amazon includes, and helper aliases.       | [site](https://git-scm.com/) · [github](https://github.com/git/git)                         |
| **tmux**     | Terminal multiplexer (panes, windows, persistent sessions); 12 tpm plugins + custom keybinds and popups.   | [site](https://github.com/tmux/tmux/wiki) · [github](https://github.com/tmux/tmux)          |
| **neovim**   | Hyperextensible Vim-based editor; a LazyVim-based config with ~13 custom plugin specs. Aliased to `v`.     | [site](https://neovim.io/) · [github](https://github.com/neovim/neovim)                     |
| **zsh**      | The interactive shell itself; modular config under `.config/zsh/` with Zinit plugins and custom functions. | [site](https://www.zsh.org/) · [github](https://github.com/zsh-users/zsh)                   |

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
