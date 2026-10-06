# zsh

export XDG_CONFIG_HOME="$HOME/.config"
export TERM=xterm-256color
export EDITOR='nvim'

bindkey -v

source $HOME/.zprofile
source $XDG_CONFIG_HOME/zsh/.zshrc-aliases
source $XDG_CONFIG_HOME/zsh/.zshrc-functions

if [[ "$OSTYPE" == "darwin"* ]]; then
  export HOMEBREW_NO_AUTO_UPDATE=1

  source $HOME/.secrets

  export SYSTEM=$_SYSTEM

  export NAVI=$HOME/navi
  export WORKSPACE="$HOME/workspace"
  export NOTO=$NAVI/noto
  export ATN_DIR="$NOTO/-buffer"
  export NVIM_SW_BUFFER_DIR="$_NVIM_SW_BUFFER_DIR"
  export NVIM_OBSD_VAULT_NAME="$_NVIM_OBSD_VAULT_NAME"
  export NVIM_OBSD_VAULT_PATH="$_NVIM_OBSD_VAULT_PATH"
  export NVIM_OBSD_VAULT_NAME_WORK="$_NVIM_OBSD_VAULT_NAME_WORK"
  export NVIM_OBSD_VAULT_PATH_WORK="$_NVIM_OBSD_VAULT_PATH_WORK"

  export PATH="/opt/homebrew/bin:/opt/homebrew/lib/luarocks/rocks-5.4:$NAVI/navi-scripts:$NAVI/navi-scripts/logging:$HOME/Library/Python/3.9/bin:$PATH"

  if [[ "$SYSTEM" == "navi"* ]]; then
    export OPENAI_API_KEY=$_OPENAI_API_KEY
    export ANTHROPIC_API_KEY=$_ANTHROPIC_API_KEY
    export ELEVENLABS_API_KEY="$_ELEVENLABS_API_KEY"
    export ELEVENLABS_VOICE_ID="$_ELEVENLABS_VOICE_ID"

    source $NAVI/navi-scripts/functions.sh
  fi
fi

export BUN_INSTALL="$HOME/.bun"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

export PATH="$HOME/.opencode/bin:$BUN_INSTALL/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

export NPM_TOKEN=$_NPM_TOKEN
export GITHUB_USER_NAME="$_GITHUB_USER_NAME"

export N_PRESERVE_NPM=1

export DEFAULT_PORT="8080"
export DEV_PORTS="8080 8081 8082 8083 8084 8085"

# zsh history
HISTSIZE=10000
SAVEHIST=3
HISTFILE=$HOME/.cache/zsh/history

# Manually initialize compinit (without using oh-my-zsh)
compinit -d "$HOME/.cache/zsh/.zcompdump"

# Load zsh help files
unalias run-help 2>/dev/null
autoload run-help
HELPDIR=/usr/local/share/zsh/help
alias help=run-help

eval "$(starship init zsh)"
eval "$(luarocks path --bin)"

# Notify via herdr when a long-running command finishes (Ghostty can't see commands inside herdr)
if [[ -n "$HERDR_ENV" ]]; then
  autoload -Uz add-zsh-hook
  NOTIFY_THRESHOLD=5
  NOTIFY_IGNORE=(nvim vim vi less man top htop btop ssh claude codex opencode herdr lazygit tig fzf f)

  _notify_preexec() {
    _notify_cmd_start=$SECONDS
    _notify_cmd_name=$1
  }

  _notify_precmd() {
    local exit=$?
    [[ -n "$_notify_cmd_start" ]] || return
    local elapsed=$(( SECONDS - _notify_cmd_start ))
    unset _notify_cmd_start
    (( elapsed >= NOTIFY_THRESHOLD )) || return
    (( ${NOTIFY_IGNORE[(Ie)${${(z)_notify_cmd_name}[1]}]} )) && return
    local title
    (( exit == 0 )) && title="✅ Done" || title="❌ Failed ($exit)"
    herdr notification show "$title" --body "$_notify_cmd_name (${elapsed}s)" \
      --sound $([[ $exit -eq 0 ]] && echo done || echo request) >/dev/null 2>&1 &!
  }

  add-zsh-hook preexec _notify_preexec
  add-zsh-hook precmd _notify_precmd
fi

export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
  --bind 'alt-g:first,alt-G:last' \
  --bind 'ctrl-d:half-page-down,ctrl-u:half-page-up' \
  --bind 'ctrl-a:select-all,ctrl-x:deselect-all' \
  --bind 'ctrl-/:toggle-preview'"

# Syntax highlighting must be loaded after other shell integrations.
if [[ "$OSTYPE" == "darwin"* ]]; then
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
