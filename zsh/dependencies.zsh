# ==============================================================================
# Tool Initialization & Dependencies
# ==============================================================================

# ------------------------------------------------------------------------------
# Starship Prompt Initialization
# ------------------------------------------------------------------------------
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"

if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
    unset RPROMPT
fi

# ------------------------------------------------------------------------------
# Zoxide Initialization (Smart Directory Jumping)
# ------------------------------------------------------------------------------
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# ------------------------------------------------------------------------------
# FZF Initialization (Fuzzy History & File Finder)
# ------------------------------------------------------------------------------
if command -v fzf &>/dev/null; then
    export FZF_DEFAULT_OPTS=" \
      --color=bg+:#252526,bg:#1e1e1e,spinner:#007acc,hl:#3794ff \
      --color=fg:#cccccc,header:#007acc,info:#858585,pointer:#007acc \
      --color=marker:#4ec9b0,fg+:#ffffff,prompt:#3794ff,hl+:#75beff \
      --height=40% --layout=reverse --border --prompt='󰭎 ' --pointer='▶' --marker='✓'"

    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
    fi

    source <(fzf --zsh)
fi
