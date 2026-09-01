# Shell colors for interactive dev-container terminals.
case $- in
    *i*) ;;
    *) return ;;
esac

git_branch() {
    local branch
    branch=$(git branch --show-current 2>/dev/null) || return
    [ -n "$branch" ] && printf ' (%s)' "$branch"
}

PS1='\[\e[1;38;5;45m\]\u@\h\[\e[0m\] \[\e[38;5;220m\]\w\[\e[0m\]\[\e[38;5;141m\]$(git_branch)\[\e[0m\]\n\[\e[1;38;5;45m\]$ \[\e[0m\]'

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'