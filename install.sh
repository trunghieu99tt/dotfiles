#!/usr/bin/env bash
#
# install.sh — symlink dotfiles from this repo into your home directory.
#
# Usage:
#   ./install.sh          # create symlinks (backs up existing files)
#   ./install.sh --dry    # show what would happen, change nothing
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_SRC="$DOTFILES_DIR/home"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

DRY=false
[[ "${1:-}" == "--dry" ]] && DRY=true

link() {
  local src="$1" dest="$2"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "ok    $dest"
    return
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    echo "backup $dest -> $BACKUP_DIR"
    if ! $DRY; then
      mkdir -p "$BACKUP_DIR/$(dirname "${dest#"$HOME"/}")"
      mv "$dest" "$BACKUP_DIR/${dest#"$HOME"/}"
    fi
  fi
  echo "link  $dest -> $src"
  if ! $DRY; then
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
  fi
}

# home/* -> ~/*  (dotglob so hidden files like .zshrc are included too)
shopt -s dotglob nullglob
for f in "$HOME_SRC"/*; do
  base="$(basename "$f")"
  [[ "$base" == "." || "$base" == ".." ]] && continue
  link "$f" "$HOME/$base"
done
shopt -u dotglob nullglob

echo
echo "Done. Backups (if any) are in: $BACKUP_DIR"
