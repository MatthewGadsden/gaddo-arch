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

eval "$(oh-my-posh init bash)"
eval "$(oh-my-posh init bash --config ~/.config/gaddo-omp-prompt.json)"

# Sloth greeting on startup
[[ -f ~/.config/sloth-greeting.sh ]] && bash ~/.config/sloth-greeting.sh
