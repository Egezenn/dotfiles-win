# ==============================================================================
# Zsh Settings & Completion (Gruvbox Dark themed)
# ==============================================================================

# Deduplicate PATH entries
typeset -U path PATH

# ------------------------------------------------------------------------------
# History Configuration
# ------------------------------------------------------------------------------
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000

setopt EXTENDED_HISTORY          # Record timestamp and duration of commands
setopt INC_APPEND_HISTORY        # Write to history file immediately after execution
setopt SHARE_HISTORY             # Share history across terminal sessions
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded
setopt HIST_IGNORE_ALL_DUPS      # Delete older duplicates when a command is repeated
setopt HIST_FIND_NO_DUPS         # Do not display duplicates when searching history
setopt HIST_IGNORE_SPACE         # Do not record commands that start with a space
setopt HIST_REDUCE_BLANKS        # Remove unnecessary whitespace
setopt HIST_VERIFY               # Review history expansions before executing

# ------------------------------------------------------------------------------
# Shell Options
# ------------------------------------------------------------------------------
setopt AUTO_CD                   # Type directory name to cd into it
setopt AUTO_PUSHD                # Make cd push the old directory onto the directory stack
setopt PUSHD_IGNORE_DUPS         # Don't push duplicate directories onto stack
setopt NO_BEEP                   # Disable annoying terminal beeps
setopt INTERACTIVE_COMMENTS      # Allow comments even in interactive shells
setopt PROMPT_SUBST              # Parameter expansion and command substitution in prompts

# ------------------------------------------------------------------------------
# Completion System & Styling (Gruvbox Dark Palette)
# ------------------------------------------------------------------------------
zmodload -i zsh/complist

autoload -Uz compinit
# Speed up compinit by checking dump file once per day
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Completion matching: case-insensitive & partial-word completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Interactive menu selection (arrow keys navigation)
zstyle ':completion:*' menu select=2
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

# Use LS_COLORS for completion list colors
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Group matches and format categories
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{#3794ff}󰉋 %d%f'
zstyle ':completion:*:messages' format '%F{#9cdcfe}󰌑 %d%f'
zstyle ':completion:*:warnings' format '%F{#f14c4c}󰅚 No matches for: %d%f'
zstyle ':completion:*:corrections' format '%F{#dcdcaa}󱍸 %d (errors: %e)%f'

# Completers to use
zstyle ':completion:*' completer _extensions _complete _approximate

# Cache expensive completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

# MSYS2 Windows Drive Completion: register mounted drives under / as fake-files
() {
    local -a drives
    if [[ -f /proc/mounts ]]; then
        local src mount_pt rest
        while read -r src mount_pt rest; do
            if [[ "$src" = [A-Za-z]: && "$mount_pt" = /* ]]; then
                drives+=("${mount_pt#/}")
            fi
        done < /proc/mounts
    elif (( $+commands[mount] )); then
        drives=($(mount | awk '/^[A-Za-z]: on \/[a-z] / { print substr($3, 2) }'))
    fi
    (( $#drives )) && zstyle ':completion:*' fake-files "/:${(j. .)drives}"
}
