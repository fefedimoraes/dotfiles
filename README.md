# .dotfiles

This repository contains `dotfiles` configuration files for multiple applications, including terminal emulators, shells, tmux, nvim, and other CLI applications.

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
