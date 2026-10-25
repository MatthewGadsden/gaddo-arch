# gaddo-arch

My Arch Linux setup: Hyprland on an Intel + NVIDIA (GTX 1050 Ti, 580xx driver) laptop,
with scripts to rebuild it from a blank disk.

## Install from scratch

> [!WARNING]
> `01-base.sh` **erases the disk you pick.** Back up anything not in this repo first
> (`~/.ssh`, `~/.gnupg`, browser profiles, `~/source`, photos, etc.).

### 1. Base system (from the Arch ISO)

Boot the Arch USB in **UEFI mode**, then:

```bash
iwctl station wlan0 connect "<SSID>"     # only if on Wi-Fi
curl -LO https://raw.githubusercontent.com/MatthewGadsden/gaddo-arch/main/install/01-base.sh
bash 01-base.sh
```

It asks for the target disk (type it twice to confirm) and passwords for `gaddo` and
`root`, then runs unattended:

- Partitions: 1G EFI (`/boot`), 47G ext4 root, ext4 `/home` on the rest
- Installs `linux` + `linux-lts`, firmware, CPU microcode, GRUB, NetworkManager, zram swap
- Sets timezone `Australia/Melbourne`, locale `en_AU.UTF-8`, hostname `akame`
- Creates user `gaddo` (sudo via `wheel`) and clones this repo to `~/source/gaddo-arch`

Override the disk or root size with environment variables:

```bash
DISK=/dev/sda ROOT_SIZE=60G bash 01-base.sh
```

### 2. Packages, drivers and dotfiles (after first boot)

Remove the USB, reboot, log in as `gaddo` on the TTY, then:

```bash
nmcli device wifi connect "<SSID>" --ask  # only if on Wi-Fi
~/source/gaddo-arch/install/02-post.sh
```

This:

- Installs every package in [`install/pkglist.txt`](install/pkglist.txt)
- Builds the AUR packages in [`install/aurlist.txt`](install/aurlist.txt) with `makepkg`
  into `~/aur` (1Password, Claude Code, NVIDIA 580xx driver)
- Adds the NVIDIA modules to the initramfs and enables NVIDIA suspend/resume
- Sets SDDM to autologin into Hyprland, enables PipeWire
- Installs oh-my-posh and bun
- Copies the dotfiles into place (existing files are kept as `*.pre-setup`)

Reboot when it finishes and SDDM drops you into Hyprland.

## Keeping it up to date

After installing packages or changing configs, snapshot the current machine back into the repo:

```bash
~/source/gaddo-arch/install/capture.sh
git diff                                 # review
git commit -am "chore: sync" && git push
```

`capture.sh` regenerates the package lists and copies the tracked configs. To track another
`~/.config` entry or home dotfile, add it to `CONFIG_ITEMS` / `HOME_ITEMS` in the script.

The repo is public, so a pre-commit hook (`.githooks/pre-commit`) runs
[gitleaks](https://github.com/gitleaks/gitleaks) on staged changes and blocks the commit if
it finds a secret. `02-post.sh` enables it; on an existing clone run
`git config core.hooksPath .githooks`. Keep secrets out of tracked files (e.g. in an
untracked `~/.bashrc.local`).

## Layout

| Path | Deployed to |
| --- | --- |
| `hypr/`, `nvim/`, `waybar/`, `rofi/`, `*.ans`, `*.json`, … (repo root) | `~/.config/` |
| `home/` | `~/` (`.bashrc`, `.bash_profile`, `.gitconfig`) |
| `install/` | Install scripts and package lists (not deployed) |

The Neovim config is based on [AstroNvim](https://github.com/AstroNvim/AstroNvim) v5.

## Notes

- AUR packages are built with `--noconfirm`, without stopping to review PKGBUILDs.
  Remove the flag in `02-post.sh` if you want to inspect them.
- Hardware-specific bits live in the scripts: GRUB kernel parameters, the NVIDIA modules
  in `mkinitcpio`, and `nvidia-580xx-utils` in `aurlist.txt`. Adjust them for a machine
  without an NVIDIA GPU.
- Test changes to the install scripts in a VM before running them on real hardware.
