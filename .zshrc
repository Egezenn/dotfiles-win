export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

for config_file in settings aliases binds plugins dependencies oddities; do
    source "$XDG_CONFIG_HOME/zsh/${config_file}.zsh"
done
