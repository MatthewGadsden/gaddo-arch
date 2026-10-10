#!/usr/bin/env bash
# Snapshot this machine's package lists and dotfiles into the repo.
# Run it, review `git diff`, then commit + push before reinstalling.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERE="$REPO_DIR/install"

# ~/.config entries to track (copied to the repo root)
CONFIG_ITEMS=(
  hypr nvim waybar kitty rofi
  gaddo-omp-prompt.json sloth-greeting.sh tokyo-snow.theme mimeapps.list
  sloth.ans akame.ans akame-color.ans akame-outline.ans akame-poster.ans
)
# ~ entries to track (copied to repo/home)
HOME_ITEMS=(.bashrc .bash_profile .gitconfig)

pacman -Qqen > "$HERE/pkglist.txt"

# AUR packages by pkgbase, since split packages (nvidia-580xx-dkms, opencl-nvidia-580xx)
# are built from one PKGBUILD (nvidia-580xx-utils)
for pkg in $(pacman -Qqem); do
  read -r name ver < <(pacman -Q "$pkg")
  sed -n '/^%BASE%$/{n;p}' "/var/lib/pacman/local/$name-$ver/desc"
done | sort -u > "$HERE/aurlist.txt"

for item in "${CONFIG_ITEMS[@]}"; do
  [[ -e $HOME/.config/$item ]] || { echo "skip: ~/.config/$item not found"; continue; }
  rm -rf "${REPO_DIR:?}/$item"
  cp -a "$HOME/.config/$item" "$REPO_DIR/$item"
done

mkdir -p "$REPO_DIR/home"
for item in "${HOME_ITEMS[@]}"; do
  cp -a "$HOME/$item" "$REPO_DIR/home/$item"
done

# drop editor/backup leftovers
find "$REPO_DIR" -path "$REPO_DIR/.git" -prune -o -name '*.bak*' -exec rm -rf {} +

echo "Captured $(wc -l < "$HERE/pkglist.txt") repo packages, $(wc -l < "$HERE/aurlist.txt") AUR packages."
git -C "$REPO_DIR" status --short
