#!/usr/bin/env bash
tmux_name="Terminal multiplexor"
tmux_description="Terminal multiplexor"
tmux_version="System dependent"
tmux_tags=("terminal" "customDesktop")
tmux_systemcategories=("System" "Utility")
tmux_launcherkeynames=("defaultLauncher")
tmux_defaultLauncher_exec="tmux"
tmux_defaultLauncher_terminal="true"
tmux_packagenames=("tmux")
tmux_packagedependencies=("xdotool" "xclip" "tmuxp" "bash-completion")
tmux_bashfunctions=("tmux_functions.sh")
tmux_filekeys=("tmuxconf" "clockmoji")
tmux_clockmoji_content="tmux_clockmoji.sh"
tmux_clockmoji_path="clockmoji.sh"
tmux_tmuxconf_content="tmux.conf"
tmux_tmuxconf_path="${HOME_FOLDER}/.tmux.conf"
tmux_cronjobs=("cronjob")
