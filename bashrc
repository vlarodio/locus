export HISTCONTROL=ignoreboth
export HISTSIZE=10000
export HISTFILESIZE=20000

shopt -s histappend checkwinsize

if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
fi

alias ls='ls --color=auto'
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'

__locus_prompt() {
  local branch gitpart
  branch="$(git branch --show-current 2>/dev/null)"
  gitpart=""
  if [ -n "$branch" ]; then
    gitpart=" \[\e[38;2;249;226;175m\]($branch)\[\e[0m\]"
  fi
  PS1="\[\e[38;2;137;180;250m\]locus\[\e[0m\]:\[\e[1;38;2;166;227;161m\]\w\[\e[0m\]${gitpart}\n\[\e[38;2;203;166;247m\]$\[\e[0m\] "
}

PROMPT_COMMAND=__locus_prompt
__locus_prompt
