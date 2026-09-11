# ==============================================================================
# Tool Initialization & Dependencies
# ==============================================================================

local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ ! -d "$cache_dir" ]] && mkdir -p "$cache_dir"

# ------------------------------------------------------------------------------
# Starship Prompt Initialization
# ------------------------------------------------------------------------------
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"

if (( $+commands[starship] )); then
    local cache="$cache_dir/starship.zsh"
    if [[ ! -f "$cache" || "$cache" -ot "$commands[starship]" ]]; then
        starship init zsh --print-full-init > "$cache"
    fi
    source "$cache"
    unset RPROMPT
fi

# ------------------------------------------------------------------------------
# Zoxide Initialization (Smart Directory Jumping)
# ------------------------------------------------------------------------------
if (( $+commands[zoxide] )); then
    local cache="$cache_dir/zoxide.zsh"
    if [[ ! -f "$cache" || "$cache" -ot "$commands[zoxide]" ]]; then
        zoxide init zsh > "$cache"
    fi
    source "$cache"
fi

# ------------------------------------------------------------------------------
# FZF Initialization (Fuzzy History & File Finder)
# ------------------------------------------------------------------------------
if (( $+commands[fzf] )); then
    export FZF_DEFAULT_OPTS=" \
      --color=bg+:#252526,bg:#1e1e1e,spinner:#007acc,hl:#3794ff \
      --color=fg:#cccccc,header:#007acc,info:#858585,pointer:#007acc \
      --color=marker:#4ec9b0,fg+:#ffffff,prompt:#3794ff,hl+:#75beff \
      --height=40% --layout=reverse --border --prompt='󰭎 ' --pointer='▶' --marker='✓'"

    if (( $+commands[fd] )); then
        export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
    fi

    local cache="$cache_dir/fzf.zsh"
    if [[ ! -f "$cache" || "$cache" -ot "$commands[fzf]" ]]; then
        fzf --zsh > "$cache"
    fi
    source "$cache"
fi
