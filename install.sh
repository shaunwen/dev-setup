#!/usr/bin/env bash
# Minimal dev env bootstrap for a fresh Apple Silicon Mac. Safe to re-run.
set -euo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$HOME/dotfiles"
NVIM_DIR="$HOME/.config/nvim"

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

install_xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then return; fi
  log "Installing Xcode Command Line Tools (finish the GUI prompt, then re-run this script)"
  xcode-select --install
  exit 0
}

install_homebrew() {
  if [[ ! -x /opt/homebrew/bin/brew ]]; then
    log "Installing Homebrew (enter your macOS password when asked)"
    if ! groups | grep -qw admin; then
      echo "User $USER is not an administrator; grant admin rights in System Settings > Users & Groups first" >&2
      exit 1
    fi
    sudo -v
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
  if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
  fi
}

install_packages() {
  log "Installing packages"
  brew bundle --file=- <<'EOF'
brew "git"
brew "stow"
brew "neovim"
brew "tmux"
brew "herdr"
brew "bitwarden-cli"
brew "ripgrep"
brew "fd"
brew "fzf"
brew "node"
brew "direnv"
brew "zoxide"
brew "mise"
brew "pnpm"
brew "starship"
brew "atuin"
brew "forgit"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "zsh-completions"
brew "coreutils"
brew "glow"
brew "jq"
brew "qrencode"
cask "neovide-app"
cask "rio"
cask "karabiner-elements"
cask "raycast"
cask "brave-browser"
cask "font-jetbrains-mono-nerd-font"
EOF
}

clone_or_pull() {
  local repo="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" pull --ff-only
  else
    if [[ -e "$dest" ]]; then mv "$dest" "$dest.bak.$(date +%s)"; fi
    git clone "$repo" "$dest"
  fi
}

setup_neovim() {
  log "Setting up Neovim config"
  mkdir -p "$HOME/.config"
  clone_or_pull https://github.com/shaunwen/nvim.git "$NVIM_DIR"
  git -C "$NVIM_DIR" remote set-url --push origin git@github.com:shaunwen/nvim.git
  nvim --headless "+Lazy! restore" +qa || echo "Lazy restore reported errors; open nvim to finish"
}

backup_unmanaged() {
  local target
  for target in "$@"; do
    if [[ -e "$HOME/$target" && ! -L "$HOME/$target" ]]; then
      mv "$HOME/$target" "$HOME/$target.bak.$(date +%s)"
    fi
  done
}

setup_dotfiles() {
  log "Linking zsh, starship, atuin, glow, tmux, neovide, herdr, rio and karabiner configs from dotfiles"
  clone_or_pull https://github.com/shaunwen/dotfiles.git "$DOTFILES_DIR"
  git -C "$DOTFILES_DIR" remote set-url --push origin git@github.com:shaunwen/dotfiles.git
  mkdir -p "$HOME/.config/"{neovide,herdr,rio,atuin,glow,karabiner}
  backup_unmanaged .zshrc .zshenv .tmux.conf .config/starship.toml .config/atuin/config.toml .config/karabiner/karabiner.json
  for pkg in zsh starship atuin glow tmux neovide herdr rio karabiner; do
    stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "$pkg"
  done
}

setup_uv() {
  log "Installing uv"
  if [[ ! -x "$HOME/.local/bin/uv" ]]; then
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
  fi
  # .zshrc sources this file unconditionally; uv's installer only writes it when allowed to edit rc files
  if [[ ! -f "$HOME/.local/bin/env" ]]; then
    cat >"$HOME/.local/bin/env" <<'EOF'
#!/bin/sh
case ":${PATH}:" in
  *:"$HOME/.local/bin":*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
EOF
  fi
}

setup_js_runtimes() {
  log "Installing node and bun with mise"
  mise use --global node@24 bun@latest
  export PATH="$HOME/.local/share/mise/shims:$HOME/.bun/bin:$PATH"
}

setup_dsh() {
  local profile_dir="$HOME/.dsh/profiles/cctui"
  log "Installing DeepSeek harness (dsh) and the cctui profile"
  bun add --global @deepseek-ai/dsh
  if [[ ! -f "$profile_dir/package.json" ]]; then
    mkdir -p "$profile_dir"
    cp -R "$DOTFILES_DIR/dsh/profiles/cctui/." "$profile_dir/"
  fi
  dsh plugin --profile cctui -- install --frozen-lockfile
}

setup_tmux_plugins() {
  log "Installing tmux plugins"
  clone_or_pull https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  "$HOME/.tmux/plugins/tpm/bin/install_plugins"
}

setup_herdr_plugins() {
  log "Installing herdr plugins"
  herdr plugin install cloudmanic/herdr-plus || true
  herdr plugin install JanTvrdik/herdr-command-palette || true
}

setup_raycast() {
  local export_file
  export_file="$(find "$BUNDLE_DIR/configs/raycast" -name '*.rayconfig' 2>/dev/null | head -1)"
  if [[ -n "$export_file" ]]; then
    log "Opening Raycast export for import (enter its password when prompted)"
    open -a Raycast "$export_file"
  else
    log "No .rayconfig found in configs/raycast - skipping Raycast import"
  fi
}

main() {
  install_xcode_clt
  install_homebrew
  install_packages
  setup_neovim
  setup_dotfiles
  setup_uv
  setup_js_runtimes
  setup_dsh
  setup_tmux_plugins
  setup_herdr_plugins
  setup_raycast
  log "Done. Open a new terminal to load zsh, open Karabiner-Elements once to grant its permissions, run 'bw login' for the Bitwarden CLI, and set DEEPSEEK_API_KEY (e.g. in ~/.zshrc.local) before 'dsh --profile cctui'."
}

main "$@"
