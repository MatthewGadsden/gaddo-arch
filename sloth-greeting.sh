#!/usr/bin/env bash
# Startup greeting: art on the left, system info on the right.

sloth_file=~/.config/david-poster.ans

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

mapfile -t art < "$sloth_file"
# Animated art holds several frames, separated by lines with a single form feed
frame_starts=(0)
for i in "${!art[@]}"; do
    [[ ${art[i]} == $'\f' ]] && frame_starts+=($((i + 1)))
done
frame_h=$(( ${#frame_starts[@]} > 1 ? frame_starts[1] - 1 : ${#art[@]} ))
sloth=("${art[@]:0:frame_h}")

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

# Animated art loops over the art just printed, redrawing it at its screen position.
# From .bashrc (GREETING_PIDFILE set) it runs in the background behind the prompt and
# .bashrc's hooks stop it on the first command; run any other way it loops in the
# foreground until a key is pressed. Skipped unless the art fits on the terminal.
frame_delay=0.07
frame_col=$(( ${#pad_left} + 1 ))

# Draw the frame starting at art line $1 with its top at screen row $2, cursor kept put
draw_frame() {
    local out=$'\e7' i
    for ((i = 0; i < frame_h; i++)); do
        out+=$'\e['"$(($2 + i));${frame_col}H${art[$1 + i]}"
    done
    printf '%s\e8' "$out"
}

# Loop the frames at screen row $1. Background: stop on SIGTERM, when the shell that
# started us exits or when the terminal is resized (the art moves). Foreground: on a key.
animate() {
    local top=$1 shell_pid=$2 size=$3 tick start n=0
    if [[ $shell_pid ]]; then
        trap 'exit 0' TERM
        exec {tick}<> <(:)  # never readable, so read -t on it is a plain delay
    fi
    while :; do
        for start in "${frame_starts[@]:1}" 0; do
            draw_frame "$start" "$top" || exit 0
            if [[ $shell_pid ]]; then
                read -rt "$frame_delay" -u "$tick" _
                if ((++n % 7 == 0)); then
                    kill -0 "$shell_pid" 2>/dev/null || exit 0
                    [[ $(stty size < /dev/tty 2>/dev/null) == "$size" ]] || exit 0
                fi
            else
                read -rsn1 -t "$frame_delay" _ && return
            fi
        done
    done
}

if ((${#frame_starts[@]} > 1)) && [[ -t 0 && -t 1 ]]; then
    size=$(stty size 2>/dev/null)
    # Scroll now if the prompt would need room, so it can't move the art once measured
    printf '\n\n\n\e[3A'
    IFS='[;' read -rs -d R -t 1 -p $'\e[6n' _ cur_row _ 2>&1
    top=$(( ${cur_row:-0} - rows - 2 ))
    if ((top >= 1 && ${size%% *} > rows + 4)); then
        if [[ $GREETING_PIDFILE ]]; then
            animate "$top" "$PPID" "$size" < /dev/null &
            echo "$!" > "$GREETING_PIDFILE"
        else
            trap 'printf "\e[?25h"' EXIT
            printf '\e[?25l'
            animate "$top"
            draw_frame 0 "$top"
            printf '\e[?25h'
        fi
    fi
fi
