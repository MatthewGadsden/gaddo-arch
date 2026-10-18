#!/usr/bin/env bash
# Stage 2 — run as your user after the first boot (from the TTY, needs network).
# Installs packages + AUR, sets up the NVIDIA driver, SDDM autologin into Hyprland,
# user tools and dotfiles. Safe to re-run.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERE="$REPO_DIR/install"
AUR_DIR="$HOME/aur"
EXTRA_REPOS=(
  "https://github.com/MatthewGadsden/mgadsden-configs.git"
)

die() { echo "error: $*" >&2; exit 1; }
step() { printf '\n==> %s\n' "$*"; }

[[ $EUID -ne 0 ]] || die "run as your normal user, not root"
sudo -v

# --- repo packages ---------------------------------------------------------
step "Installing repo packages"
grep -Ev '^\s*(#|$)' "$HERE/pkglist.txt" | sudo pacman -Syu --needed --noconfirm -

# --- AUR packages (built with makepkg, no helper) --------------------------
step "Building AUR packages"
# 1password's PKGBUILD verifies the tarball signature against this key
curl -fsSL https://downloads.1password.com/linux/keys/1password.asc | gpg --import
mkdir -p "$AUR_DIR"
while read -r pkg; do
  [[ -z $pkg || $pkg == \#* ]] && continue
  if [[ -d $AUR_DIR/$pkg/.git ]]; then
    git -C "$AUR_DIR/$pkg" pull --ff-only
  else
    git clone "https://aur.archlinux.org/$pkg.git" "$AUR_DIR/$pkg"
  fi
  (cd "$AUR_DIR/$pkg" && makepkg -si --needed --noconfirm)
done < "$HERE/aurlist.txt"

# --- NVIDIA early KMS ------------------------------------------------------
step "Configuring initramfs for NVIDIA"
sudo sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
sudo sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf keyboard keymap consolefont block filesystems fsck)/' /etc/mkinitcpio.conf
sudo mkinitcpio -P

# --- display manager -------------------------------------------------------
step "Configuring SDDM autologin"
sudo tee /etc/sddm.conf >/dev/null <<EOF
[Autologin]
User=$USER
Session=hyprland
EOF

# --- services --------------------------------------------------------------
step "Enabling services"
sudo systemctl enable sddm.service nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service

# --- user tools (before dotfiles: the bun installer edits .bash_profile) ---
step "Installing user tools"
mkdir -p "$HOME/.local/bin"
command -v oh-my-posh >/dev/null || curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
[[ -x $HOME/.bun/bin/bun ]] || curl -fsSL https://bun.sh/install | bash

# --- dotfiles --------------------------------------------------------------
step "Deploying dotfiles"
backup() { [[ -e $1 && ! -e $1.pre-setup ]] && mv "$1" "$1.pre-setup" || true; }

mkdir -p "$HOME/.config"
for src in "$REPO_DIR"/*; do
  name="$(basename "$src")"
  case "$name" in install|home|README.md|CLAUDE.md) continue ;; esac
  backup "$HOME/.config/$name"
  rm -rf "$HOME/.config/$name"
  cp -a "$src" "$HOME/.config/$name"
done
for src in "$REPO_DIR"/home/.[!.]*; do
  name="$(basename "$src")"
  backup "$HOME/$name"
  rm -rf "$HOME/$name"
  cp -a "$src" "$HOME/$name"
done

for url in "${EXTRA_REPOS[@]}"; do
  dest="$HOME/source/$(basename "$url" .git)"
  [[ -d $dest ]] || git clone "$url" "$dest"
done

step "Done — reboot and SDDM will log you straight into Hyprland."
