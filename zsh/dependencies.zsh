# ==============================================================================
# Tool Initialization & Dependencies
# ==============================================================================

local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ ! -d "$cache_dir" ]] && mkdir -p "$cache_dir"

# ------------------------------------------------------------------------------
# Starship Prompt Initialization
# ------------------------------------------------------------------------------
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"

local starship_cache="$cache_dir/starship.zsh"
if [[ ! -f "$starship_cache" || "$starship_cache" -ot "$commands[starship]" ]]; then
    starship init zsh --print-full-init > "$starship_cache"
fi
source "$starship_cache"
unset RPROMPT

# ------------------------------------------------------------------------------
# Zoxide Initialization (Smart Directory Jumping)
# ------------------------------------------------------------------------------
local zoxide_cache="$cache_dir/zoxide.zsh"
if [[ ! -f "$zoxide_cache" || "$zoxide_cache" -ot "$commands[zoxide]" ]]; then
    zoxide init zsh > "$zoxide_cache"
fi
source "$zoxide_cache"

# ------------------------------------------------------------------------------
# FZF Initialization (Fuzzy History & File Finder)
# ------------------------------------------------------------------------------
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#252526,bg:#1e1e1e,spinner:#007acc,hl:#3794ff \
  --color=fg:#cccccc,header:#007acc,info:#858585,pointer:#007acc \
  --color=marker:#4ec9b0,fg+:#ffffff,prompt:#3794ff,hl+:#75beff \
  --height=40% --layout=reverse --border --prompt='󰭎 ' --pointer='▶' --marker='✓'"

export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'

local fzf_cache="$cache_dir/fzf.zsh"
if [[ ! -f "$fzf_cache" || "$fzf_cache" -ot "$commands[fzf]" ]]; then
    fzf --zsh > "$fzf_cache"
fi
source "$fzf_cache"
