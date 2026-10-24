#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias clear='reset && exec "$SHELL" -l'
PS1='[\u@\h \W]\$ '

export PATH=$PATH:/home/gaddo/.local/bin

[[ -f /usr/share/nvm/init-nvm.sh ]] && source /usr/share/nvm/init-nvm.sh
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# grimshot saves screenshots here
export XDG_PICTURES_DIR=~/Pictures/screenshots/
export XDG_SCREENSHOTS_DIR=~/Pictures/screenshots/

eval "$(oh-my-posh init bash)"
eval "$(oh-my-posh init bash --config ~/.config/gaddo-omp-prompt.json)"

# Sloth greeting on startup. Animated art keeps looping behind the prompt; these hooks
# stop it before the first command runs (PS0), on the next prompt, or on Ctrl+L, since
# any of those can move or clear the screen it draws on.
__greeting_pidfile=${XDG_RUNTIME_DIR:-/tmp}/sloth-greeting.$$
rm -f "$__greeting_pidfile"  # a stale one from an earlier shell with this PID
[[ -f ~/.config/sloth-greeting.sh ]] && GREETING_PIDFILE=$__greeting_pidfile bash ~/.config/sloth-greeting.sh
if [[ -s $__greeting_pidfile ]]; then
    __greeting_stop() {
        local pid i=0
        read -r pid < "$__greeting_pidfile" 2>/dev/null || return 0
        rm -f "$__greeting_pidfile"
        kill "$pid" 2>/dev/null
        # let a frame that's mid-draw finish before anything else is printed
        while kill -0 "$pid" 2>/dev/null && ((i++ < 20)); do sleep 0.01; done
    }
    __greeting_prompts=0
    __greeting_prompt() {
        ((++__greeting_prompts > 1)) || return 0  # the first call is the first prompt
        __greeting_stop
        PS0=${PS0#'$(__greeting_stop)'}
        local cmds=() c
        for c in "${PROMPT_COMMAND[@]}"; do
            [[ $c == __greeting_prompt ]] || cmds+=("$c")
        done
        PROMPT_COMMAND=("${cmds[@]}")
        bind '"\C-l": clear-screen'
    }
    PS0='$(__greeting_stop)'"$PS0"
    PROMPT_COMMAND+=(__greeting_prompt)  # after oh-my-posh's hook, which reads $?
    bind -x '"\e[990~": __greeting_stop'
    bind '"\e[991~": clear-screen'
    bind '"\C-l": "\e[990~\e[991~"'
fi
