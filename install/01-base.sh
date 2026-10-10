#!/usr/bin/env bash
# Stage 1 — run from the Arch ISO as root. WIPES the target disk.
#
#   iwctl station wlan0 connect <SSID>        # if on Wi-Fi
#   curl -LO https://raw.githubusercontent.com/MatthewGadsden/gaddo-arch/main/install/01-base.sh
#   bash 01-base.sh
#
# Layout (matches the current machine): 1G EFI at /boot, ext4 root, ext4 /home on the rest.
# GRUB bootloader, linux + linux-lts kernels, NetworkManager, zram swap.
set -euo pipefail

DISK="${DISK:-}"                 # e.g. /dev/nvme0n1 — prompted if empty
ROOT_SIZE="${ROOT_SIZE:-47G}"
HOSTNAME="akame"
USERNAME="gaddo"
TIMEZONE="Australia/Melbourne"
LOCALE="en_AU.UTF-8"
DOTFILES_REPO="https://github.com/MatthewGadsden/gaddo-arch.git"

die() { echo "error: $*" >&2; exit 1; }

# --- preflight -------------------------------------------------------------
[[ $EUID -eq 0 ]] || die "run as root from the Arch ISO"
[[ -d /sys/firmware/efi ]] || die "not booted in UEFI mode"
ping -c1 -W3 archlinux.org >/dev/null || die "no network (use iwctl for Wi-Fi)"
timedatectl set-ntp true

if grep -q GenuineIntel /proc/cpuinfo; then UCODE=intel-ucode; else UCODE=amd-ucode; fi

# --- questions up front, so the rest runs unattended -----------------------
if [[ -z $DISK ]]; then
  lsblk -dpno NAME,SIZE,MODEL | grep -Ev 'loop|sr[0-9]|zram'
  read -rp "Disk to install to: " DISK
fi
[[ -b $DISK ]] || die "$DISK is not a block device"
read -rp "Type '$DISK' again to confirm ERASING it: " confirm
[[ $confirm == "$DISK" ]] || die "confirmation did not match"

ask_password() {
  local p1 p2
  while true; do
    read -rsp "$1 password: " p1; echo
    read -rsp "Confirm $1 password: " p2; echo
    [[ -n $p1 && $p1 == "$p2" ]] && break
    echo "Passwords empty or did not match, try again."
  done
  printf '%s' "$p1"
}
USER_PASS="$(ask_password "$USERNAME")"
ROOT_PASS="$(ask_password root)"

# nvme0n1 -> nvme0n1p1, sda -> sda1
part() { if [[ $DISK =~ [0-9]$ ]]; then echo "${DISK}p$1"; else echo "${DISK}$1"; fi; }

# --- partition & format ----------------------------------------------------
umount -R /mnt 2>/dev/null || true
wipefs -af "$DISK"
sgdisk --zap-all "$DISK"
sgdisk -n1:0:+1G           -t1:ef00 -c1:EFI  \
       -n2:0:+"$ROOT_SIZE" -t2:8304 -c2:root \
       -n3:0:0             -t3:8302 -c3:home "$DISK"
partprobe "$DISK"
udevadm settle

mkfs.fat -F32 "$(part 1)"
mkfs.ext4 -F "$(part 2)"
mkfs.ext4 -F "$(part 3)"

mount "$(part 2)" /mnt
mount --mkdir "$(part 1)" /mnt/boot
mount --mkdir "$(part 3)" /mnt/home

# --- base system -----------------------------------------------------------
pacstrap -K /mnt \
  base base-devel linux linux-headers linux-lts linux-lts-headers \
  linux-firmware sof-firmware "$UCODE" \
  grub efibootmgr networkmanager iwd sudo git vim nano neovim zram-generator

genfstab -U /mnt >> /mnt/etc/fstab

# --- configure inside the new system ---------------------------------------
arch-chroot /mnt /bin/bash -s <<EOF
set -euo pipefail

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

sed -i 's/^#\($LOCALE UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
cat > /etc/vconsole.conf <<'VC'
KEYMAP=us
XKBLAYOUT=us
XKBMODEL=pc105+inet
XKBOPTIONS=terminate:ctrl_alt_bksp
VC

echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<'HOSTS'
127.0.0.1        localhost
::1              localhost
HOSTS

echo '[zram0]' > /etc/systemd/zram-generator.conf

sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="zswap.enabled=0 rootfstype=ext4 nvidia_drm.modeset=1"/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

useradd -m -G wheel -s /bin/bash $USERNAME
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
chmod 440 /etc/sudoers.d/10-wheel

systemctl enable NetworkManager systemd-timesyncd fstrim.timer

runuser -u $USERNAME -- git clone $DOTFILES_REPO /home/$USERNAME/source/gaddo-arch
EOF

printf '%s:%s\n' "$USERNAME" "$USER_PASS" "root" "$ROOT_PASS" | arch-chroot /mnt chpasswd

umount -R /mnt
cat <<MSG

Base install done. Next:
  1. reboot (remove the USB)
  2. log in as $USERNAME on the TTY
  3. nmcli device wifi connect <SSID> --ask     # if on Wi-Fi
  4. ~/source/gaddo-arch/install/02-post.sh
MSG
