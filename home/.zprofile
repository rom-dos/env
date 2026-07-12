if [[ $OSTYPE == darwin* ]]; then
    osascript -e 'tell app "Finder" to quit'

    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

eval "$(luarocks path --bin)"

export ZDOTDIR="$HOME/.config/zsh"

if [ ! -p /tmp/nnn.fifo ]; then
    mkfifo /tmp/nnn.fifo
fi

export NNN_FIFO=/tmp/nnn.fifo
export NNN_PLUG='i:nnn-img-preview;s:-!echo $PWD/$nnn|pbcopy'
export NNN_TERMINAL=tmux
export NNN_OPENER="$HOME/.config/nnn/opener.sh"
export NNN_COPIER="pbcopy"
export IMG_PREVIEW_VIEWER=quicklook

export BAT_THEME_DARK="base16-256"
export MANPAGER="sh -c 'col -bx | bat --theme-dark=base16-256 -l man -p'"

export OPENCODE_EXPERIMENTAL_PLAN_MODE=1
