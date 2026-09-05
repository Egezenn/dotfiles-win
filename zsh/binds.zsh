# ==============================================================================
# Zsh Keybindings
# ==============================================================================

# Use Emacs keybindings mode
bindkey -e

# Navigation keybindings (Home, End, Delete, Ctrl+Arrows)
bindkey "^[[H"    beginning-of-line
bindkey "^[OH"    beginning-of-line
bindkey "^[[1~"   beginning-of-line
bindkey "^[[F"    end-of-line
bindkey "^[OF"    end-of-line
bindkey "^[[4~"   end-of-line
bindkey "^[[3~"   delete-char
bindkey "^[[1;5D" backward-word
bindkey "^[[5D"   backward-word
bindkey "^[[1;5C" forward-word
bindkey "^[[5C"   forward-word
bindkey "^[[3;5~" kill-word
bindkey "^H"      backward-kill-word
bindkey "^W"      backward-kill-word

# Shift-Tab for cycling backwards in completion menu
bindkey "^[[Z"    reverse-menu-complete

# History Substring Search bindings (Up / Down arrows)
bindkey "^[[A"    history-substring-search-up
bindkey "^[OA"    history-substring-search-up
bindkey "^[[B"    history-substring-search-down
bindkey "^[OB"    history-substring-search-down

# zsh-autosuggestions bindings
# Ctrl+F or Ctrl+Space to accept complete suggestion
bindkey "^F"      autosuggest-accept
bindkey "^ "      autosuggest-accept
# Alt+F to accept next word
bindkey "^[f"     forward-word
