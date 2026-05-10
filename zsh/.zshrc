# homebrew (must be first to take precedence over other PATH entries)
export PATH="/opt/homebrew/bin:$PATH"

# peco
function peco-history-selection() {
    BUFFER=`history -n 1 | tail -r  | awk '!a[$0]++' | peco`
    CURSOR=$#BUFFER
    zle reset-prompt
}

zle -N peco-history-selection
bindkey '^R' peco-history-selection

# zsh-autosuggestions
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

# bun completions
[ -s "/Users/mossagate/.bun/_bun" ] && source "/Users/mossagate/.bun/_bun"

# mise
eval "$(/opt/homebrew/bin/mise activate zsh)"

# starship
eval "$(starship init zsh)"

# alias
alias gaa='git add -A'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gbr='git branch'
alias gac='git add -A && git commit -m'
alias gchb='git checkout -b'
alias gch='git checkout'
alias gst='git status'
alias gs='git stash -u'
alias gsa='git stash apply'
alias gcc='git cherry-pick'
alias gp='git pull origin'
alias ge='git merge'
alias gc='git add -A && git cz'
alias gf='git fetch'
alias yi='ni'
alias y='nr'
alias yd='nr dev'
alias yu='nun'
alias yg='nr git'
alias gd='git pull origin develop'
alias gm='git pull origin main'
alias gmm='git check main && git pull origin main'
alias webstorm='open -na "WebStorm.app" --args nosplash "$@"'
alias i='npm i -g @antfu/ni'
alias wb='webstorm .'
alias z='code ~/.zshrc'
alias b='bat ~/.zshrc'
alias m='make'
alias t='touch'
alias vv='claude --dangerously-skip-permissions'
alias vvu='brew upgrade --cask claude-code'
alias xx='codex --dangerously-bypass-approvals-and-sandbox'
alias xxu='brew upgrade codex'
alias ll='lazygit'

# 現在のブランチをプッシュ
function gu() {
   BRANCH=$(git symbolic-ref --short HEAD | tr -d '\n') # カレントブランチ名を取得
   git push origin $BRANCH
}

function cdc {
  cd ~/code
}

function cdd {
  cd ~/desktop
}

function op {
  open .
}

function co {
  cursor .
}

function vs {
  code .
}

## mkdir && cd の同時実行
function mkcd {
  if [ ! -n "$1" ]; then
    echo "Enter a directory name"
  elif [ -d $1 ]; then
    echo "\`$1' already exists"
  else
    mkdir $1 && cd $1
  fi
}

# ezaの時のディレクトリ表示カスタマイズ
alias e='eza --icons'
alias ls=e
alias ea='eza -a --icons'
alias la=ea
alias ee='eza -aal --icons'
alias et='eza -T -L 3 -a -I "node_modules|.git|.cache" --icons'
alias lt=et
alias eta='eza -T -a -I "node_modules|.git|.cache" --color=always --icons | less -r'
alias lta=eta

# 移動など
alias ..='cd ..'
alias ...='cd ...'
alias ....='cd ....'
alias .....='cd .....'
alias ~='cd ~'