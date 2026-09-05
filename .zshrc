export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

for config_file in settings aliases binds plugins dependencies oddities; do
    if [[ -f "$XDG_CONFIG_HOME/zsh/${config_file}.zsh" ]]; then
        source "$XDG_CONFIG_HOME/zsh/${config_file}.zsh"
    fi
done
