# zsh

export XDG_CONFIG_HOME="$HOME/.config"
export TERM=xterm-256color
export EDITOR='nvim'

bindkey -v

source $HOME/.zprofile
source $XDG_CONFIG_HOME/zsh/.zshrc-aliases

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
export GITHUB_TOKEN=$_GITHUB_TOKEN
export GITHUB_USER_NAME="$_GITHUB_USER_NAME"

export N_PRESERVE_NPM=1

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

# Syntax highlighting must be loaded after other shell integrations.
if [[ "$OSTYPE" == "darwin"* ]]; then
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
