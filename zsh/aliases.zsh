alias ls='lsd --group-directories-first'
alias l='lsd -l --group-directories-first'
alias la='lsd -a --group-directories-first'
alias ll='lsd -la --group-directories-first'
alias lt='lsd --tree --depth=2'
alias tree='lsd --tree'

alias cp='cp -i'
alias mv='mv -i'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias c='clear'
alias reload='source ~/.zshrc && echo "󰑓 Zsh configuration reloaded!"'

wr() {
  local exe_path="$1"
  shift
  "$(cygpath "$exe_path")" "$@"
}

detach() {
  nohup "$@" >/dev/null 2>&1 &
}

export MPP="$MINGW_PACKAGE_PREFIX"
