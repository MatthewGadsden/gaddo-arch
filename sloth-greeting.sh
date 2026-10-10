#!/usr/bin/env bash
# Startup greeting: art on the left, system info on the right.

sloth_file=~/.config/akame-poster.ans
[[ -f $sloth_file ]] || return 0 2>/dev/null || exit 0

theme_file=~/.config/tokyo-snow.theme
[[ -f $theme_file ]] || return 0 2>/dev/null || exit 0
source "$theme_file"

field() { printf '%s%s%-8s%s %s%s%s' "$c_bold" "$1" "$2" "$c_reset" "$c_text" "$3" "$c_reset"; }

os=$(. /etc/os-release && echo "$PRETTY_NAME")
kernel=$(uname -r)

up=$(</proc/uptime); up=${up%%.*}
d=$((up / 86400)) h=$((up % 86400 / 3600)) m=$((up % 3600 / 60))
uptime_str=""
((d)) && uptime_str+="${d}d "
((h)) && uptime_str+="${h}h "
uptime_str+="${m}m"

pkgs=$(pacman -Qq 2>/dev/null | wc -l)

cpu=$(grep -m1 'model name' /proc/cpuinfo)
cpu=${cpu#*: }; cpu=${cpu//(R)/}; cpu=${cpu//(TM)/}; cpu=${cpu% CPU @*}; cpu=${cpu/Intel Core/Core}

read -r mem_total mem_avail < <(awk '/^MemTotal/ {t=$2} /^MemAvailable/ {a=$2} END {print t, a}' /proc/meminfo)
mem="$(( (mem_total - mem_avail) / 1024 / 1024 )).$(( (mem_total - mem_avail) / 1024 % 1024 * 10 / 1024 ))G / $(( mem_total / 1024 / 1024 )).$(( mem_total / 1024 % 1024 * 10 / 1024 ))G"

disk=$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')

swatch=""
for name in "${theme_swatch[@]}"; do
    c="c_$name"
    swatch+="${!c}███${c_reset}"
done

title="${c_bold}${c_amber}${USER}${c_text}@${c_neon}${HOSTNAME}${c_reset}"
title_len=$(( ${#USER} + 1 + ${#HOSTNAME} ))
rule="${c_muted}$(printf '─%.0s' $(seq 1 "$title_len"))${c_reset}"

info=(
    "$title"
    "$rule"
    "$(field "$c_neon"  OS     "$os")"
    "$(field "$c_ember" Kernel "$kernel")"
    "$(field "$c_amber" Uptime "$uptime_str")"
    "$(field "$c_gold"  Pkgs   "$pkgs")"
    "$(field "$c_sage"  Shell  "bash ${BASH_VERSION%%(*}")"
    "$(field "$c_moss"  CPU    "$cpu")"
    "$(field "$c_pine"  Memory "$mem")"
    "$(field "$c_neon"  Disk   "$disk")"
    "$swatch"
)

mapfile -t sloth < "$sloth_file"

pad_left="      "
gap="       "
rows=$(( ${#sloth[@]} > ${#info[@]} ? ${#sloth[@]} : ${#info[@]} ))
# Width of the art = first line with colour codes stripped
# (sed, not a bash extglob substitution: that takes ~2s on long colour lines)
first=$(sed -n '1{s/\x1b\[[0-9;]*m//g;p;q}' "$sloth_file")
blank_sloth=$(printf '%*s' "${#first}" '')
# Vertically centre the info column beside the art
info_top=$(( (rows - ${#info[@]}) / 2 ))

printf '\n\n'
for ((i = 0; i < rows; i++)); do
    j=$((i - info_top))
    line=""
    ((j >= 0 && j < ${#info[@]})) && line=${info[j]}
    printf '%s%s%s%s\n' "$pad_left" "${sloth[i]:-$blank_sloth}" "$gap" "$line"
done
printf '\n\n'
