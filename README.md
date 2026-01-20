# dotfiles-wsl-fedora

Reusable dotfiles and config for my WSL Fedora environment.

## Layout
- `home/` – files that live directly in `$HOME` (e.g. `.zshrc`, `.gitconfig`, `.p10k.zsh`, `.ssh/config`).
- `config/` – subdirectories that map to `$HOME/.config` (e.g. `nvim`, `ghostty`, `zellij`, `lsd`).
- `fedora_setup.md` – notes and commands for setting up Fedora (packages, shells, tools).
- `ghostty_setup.sh` – helper script to build and install Ghostty on Fedora.

## Usage
Clone this repo, `cd` into it and run:

```bash
bash install.sh
```

This will:
- enable the required Fedora repos (COPR zellij, Microsoft),
- install your base tools (dnf packages, HashiCorp tools, Docker, AKS CLI, talosctl, NVM + GitHub Copilot CLI, zsh plugins),
- install Hack Nerd Font into your user font directory for terminal/icons, and
- (re)symlink the tracked dotfiles into your `$HOME` and `~/.config` based on this repo's contents.

Note: this script expects Fedora with `dnf` and will prompt for `sudo` where needed.