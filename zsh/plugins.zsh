# ==============================================================================
# Zsh Plugins & Themes
# ==============================================================================

PLUGIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins"

# ------------------------------------------------------------------------------
# zsh-autosuggestions
# ------------------------------------------------------------------------------
if [[ -f "$PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6a737d"
    export ZSH_AUTOSUGGEST_STRATEGY=(history)
    source "$PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# ------------------------------------------------------------------------------
# zsh-history-substring-search
# ------------------------------------------------------------------------------
if [[ -f "$PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
    export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=none,fg=#3794ff,bold'
    export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=none,fg=#f14c4c,bold'
    export HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS='i'

    source "$PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
fi
