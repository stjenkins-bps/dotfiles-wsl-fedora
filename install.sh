#!/usr/bin/env bash
set -euo pipefail

# Install Fedora packages, tools, and symlink dotfiles from this repo into $HOME
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_repos_and_packages() {
  if ! command -v dnf >/dev/null 2>&1; then
    echo "dnf not found; skipping Fedora package install" >&2
    return
  fi

  echo "==> Enabling COPR and Microsoft repos..."
  sudo dnf -y install dnf-plugins-core || true
  sudo dnf copr enable -y varlad/zellij || true

  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc || true
  curl -fsSL https://packages.microsoft.com/config/fedora/42/prod.repo \
    | sudo tee /etc/yum.repos.d/microsoft.repo >/dev/null || true
  sudo dnf makecache -y || true

  echo "==> Installing base packages..."
  sudo dnf install -y \
    dnf-plugins-core \
    wget \
    openssl \
    kubectl \
    k9s \
    azure-cli \
    helm \
    zsh \
    git \
    nvim \
    p7zip \
    p7zip-plugins \
    unzip \
    btop \
    jq \
    nmap \
    zellij \
    zoxide \
    powershell || true

  echo "==> Installing HashiCorp repo + tools (packer, terraform)..."
  wget -O- https://rpm.releases.hashicorp.com/fedora/hashicorp.repo \
    | sudo tee /etc/yum.repos.d/hashicorp.repo >/dev/null || true
  sudo dnf -y install packer terraform || true

  echo "==> Installing Docker Engine..."
  sudo dnf -y install dnf-plugins-core || true
  sudo dnf config-manager addrepo \
    --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo || true
  sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true
  sudo usermod -aG docker "$USER" || true

  echo "==> Installing Azure AKS CLI (az aks)..."
  if command -v az >/dev/null 2>&1; then
    sudo az aks install-cli || true
  fi
}

install_tools_and_shell() {
  echo "==> Installing NVM, Node, and GitHub Copilot CLI (if needed)..."
  if [[ ! -d "$HOME/.nvm" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash || true
  fi

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

  if command -v npm >/dev/null 2>&1; then
    npm install -g npm@11 @github/copilot || true
  fi

  echo "==> Installing talosctl..."
  if ! command -v talosctl >/dev/null 2>&1; then
    curl -sL https://talos.dev/install | sh || true
  fi

  echo "==> Installing zsh plugins (powerlevel10k, zsh-vi-mode)..."
  if [[ ! -d "$HOME/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k" || true
  fi
  if [[ ! -d "$HOME/.zsh-vi-mode" ]]; then
    git clone https://github.com/jeffreytse/zsh-vi-mode.git "$HOME/.zsh-vi-mode" || true
  fi

  if command -v zsh >/dev/null 2>&1 && [[ "${SHELL:-}" != "/bin/zsh" ]]; then
    echo "==> Changing default shell to zsh (you may be prompted for your password)..."
    chsh -s /bin/zsh "$USER" || true
  fi
}

install_fonts() {
  echo "==> Installing Hack Nerd Font (nerd font for terminal + icons)..."
  local font_dir="$HOME/.local/share/fonts"
  mkdir -p "$font_dir"
  if ! ls "$font_dir"/*Hack*Nerd*Font* >/dev/null 2>&1; then
    local tmpdir
    tmpdir="$(mktemp -d)"
    if curl -fLo "$tmpdir/Hack.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip; then
      unzip -o "$tmpdir/Hack.zip" -d "$font_dir" >/dev/null 2>&1 || true
    fi
    rm -rf "$tmpdir"
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -f "$font_dir" || true
    fi
  fi
}

install_repos_and_packages
install_tools_and_shell
install_fonts


link() {
  local src="$1" dst="$2"
  echo "Linking $dst -> $src"
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
}

# Top-level dotfiles
link "$DOTFILES_DIR/home/.zshrc"    "$HOME/.zshrc"
link "$DOTFILES_DIR/home/.gitconfig" "$HOME/.gitconfig"
if [[ -f "$DOTFILES_DIR/home/.p10k.zsh" ]]; then
  link "$DOTFILES_DIR/home/.p10k.zsh" "$HOME/.p10k.zsh"
fi

# SSH config (GitHub-only config, no keys)
if [[ -f "$DOTFILES_DIR/home/.ssh/config" ]]; then
  link "$DOTFILES_DIR/home/.ssh/config" "$HOME/.ssh/config"
fi

# ~/.config subdirectories
for dir in nvim ghostty zellij lsd; do
  if [[ -d "$DOTFILES_DIR/config/$dir" ]]; then
    link "$DOTFILES_DIR/config/$dir" "$HOME/.config/$dir"
  fi
done

echo "Done. Your dotfiles are now linked into $HOME from $DOTFILES_DIR."