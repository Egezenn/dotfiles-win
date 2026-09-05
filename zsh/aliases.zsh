# ==============================================================================
# Zsh Aliases & Helper Functions
# ==============================================================================

# ------------------------------------------------------------------------------
# LSD / LS Replacement
# ------------------------------------------------------------------------------
if command -v lsd &>/dev/null; then
    alias ls='lsd --group-directories-first'
    alias l='lsd -l --group-directories-first'
    alias la='lsd -a --group-directories-first'
    alias ll='lsd -la --group-directories-first'
    alias lt='lsd --tree --depth=2'
    alias tree='lsd --tree'
else
    alias ls='ls --color=auto'
    alias ll='ls -lah --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'
fi

# ------------------------------------------------------------------------------
# Directory Navigation
# ------------------------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'

# ------------------------------------------------------------------------------
# Safety & Quality of Life
# ------------------------------------------------------------------------------
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -I'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias c='clear'
alias reload='source ~/.zshrc && echo "󰑓 Zsh configuration reloaded!"'

# ------------------------------------------------------------------------------
# Utility Functions
# ------------------------------------------------------------------------------
# Create a directory and immediately enter it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# ------------------------------------------------------------------------------
# MSYS2 Environment
# ------------------------------------------------------------------------------
export MPP="$MINGW_PACKAGE_PREFIX"
