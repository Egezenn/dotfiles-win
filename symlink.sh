#!/usr/bin/env bash

set -euo pipefail

# Determine dotfiles root directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Resolve user paths
USERNAME="$(whoami)"
WIN_USER="/c/Users/${USERNAME}"
if [[ -n "${USERPROFILE:-}" ]]; then
    WIN_USER="$(cygpath -u "$USERPROFILE")"
fi

PROGRAM_FILES="/c/Program Files"
if [[ -n "${PROGRAMFILES:-}" ]]; then
    PROGRAM_FILES="$(cygpath -u "$PROGRAMFILES")"
fi

MSYS_HOME="${HOME:-/home/${USERNAME}}"
APPDATA="${WIN_USER}/AppData/Roaming"
LOCALAPPDATA="${WIN_USER}/AppData/Local"
DOCUMENTS="${WIN_USER}/Documents"

log_info() {
    echo -e "[INFO] $1"
}

log_ok() {
    echo -e "[OK] $1 -> $2"
}

log_warn() {
    echo -e "[WARN] $1"
}

link_file() {
    local src="$1"
    local dest="$2"

    if [[ ! -e "$src" ]]; then
        log_warn "Source file not found: $src (skipping)"
        return 0
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    log_ok "$src" "$dest"
}

link_dir() {
    local src="$1"
    local dest="$2"

    if [[ ! -d "$src" ]]; then
        log_warn "Source directory not found: $src (skipping)"
        return 0
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
    log_ok "$src" "$dest"
}

copy_file() {
    local src="$1"
    local dest="$2"

    if [[ ! -e "$src" ]]; then
        log_warn "Source file not found: $src (skipping)"
        return 0
    fi

    mkdir -p "$(dirname "$dest")"
    rm -f "$dest"
    cp -f "$src" "$dest"
    log_ok "$src" "$dest"
}

log_info "Starting symlink deployment from $DOTFILES_DIR"

# AltSnap
link_file "$DOTFILES_DIR/loose/AltSnap.ini" "$APPDATA/AltSnap/AltSnap.ini"

# Everything
copy_file "$DOTFILES_DIR/loose/Everything-1.5a.ini" "$APPDATA/Everything/Everything-1.5a.ini"

# Explorer++
copy_file "$DOTFILES_DIR/loose/Explorer++-config.xml" "$PROGRAM_FILES/Explorer++/config.xml"

# VSCodium & VS Code
link_file "$DOTFILES_DIR/vscode/settings.json" "$APPDATA/VSCodium/User/settings.json"
link_file "$DOTFILES_DIR/vscode/keybindings.json" "$APPDATA/VSCodium/User/keybindings.json"

if [[ -d "$APPDATA/Code/User" ]]; then
    link_file "$DOTFILES_DIR/vscode/settings.json" "$APPDATA/Code/User/settings.json"
    link_file "$DOTFILES_DIR/vscode/keybindings.json" "$APPDATA/Code/User/keybindings.json"
fi

# PowerShell (pwsh)
link_file "$DOTFILES_DIR/pwsh/Profile.ps1" "$DOCUMENTS/PowerShell/Microsoft.PowerShell_profile.ps1"
link_file "$DOTFILES_DIR/pwsh/Profile.ps1" "$DOCUMENTS/PowerShell/Profile.ps1"

# Windows Terminal
wt_found=false
for wt_dir in "$LOCALAPPDATA"/Packages/Microsoft.WindowsTerminal_*; do
    if [[ -d "$wt_dir" ]]; then
        link_file "$DOTFILES_DIR/loose/wt-settings.json" "$wt_dir/LocalState/settings.json"
        wt_found=true
    fi
done
if [[ "$wt_found" = false ]]; then
    log_warn "No Windows Terminal package directory found under $LOCALAPPDATA/Packages"
fi

# ------------------------------------------------------------------------------
# Zsh Plugins (cloned via --depth 1)
# ------------------------------------------------------------------------------
PLUGIN_DIR="$DOTFILES_DIR/zsh/plugins"
mkdir -p "$PLUGIN_DIR"

clone_plugin() {
    local name="$1"
    local repo="$2"
    local dest="$PLUGIN_DIR/$name"

    if [[ ! -d "$dest" ]]; then
        log_info "Cloning $name (--depth 1)..."
        git clone --depth 1 "$repo" "$dest"
        log_ok "$name" "$dest"
    fi
}

clone_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
clone_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search.git"

# Zsh
link_file "$DOTFILES_DIR/.zshrc" "$MSYS_HOME/.zshrc"
link_dir  "$DOTFILES_DIR/zsh" "$MSYS_HOME/.config/zsh"

# Starship
link_file "$DOTFILES_DIR/loose/starship.toml" "$MSYS_HOME/.config/starship.toml"

# Nano
link_file "$DOTFILES_DIR/nano/nanorc" "$MSYS_HOME/.config/nano/nanorc"

log_info "All symlinks processed successfully."