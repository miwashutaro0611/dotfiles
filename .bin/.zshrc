if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

function peco-history-selection() {
   BUFFER=`history -n 1 | tail -r  | awk '!a[$0]++' | peco`
   CURSOR=$#BUFFER
   zle reset-prompt
}

zle -N peco-history-selection
bindkey '^R' peco-history-selection

eval "$(anyenv init -)"

export PATH="$HOME/.nodenv/bin:$PATH"
eval "$(nodenv init -)"

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
alias gc='git add -A && git cz'
alias gf='git fetch'
alias yi='ni'
alias y='nr'
alias yd='nr dev'
alias yg='nr git'
alias gd='git pull origin develop'
alias gm='git pull origin main'
alias gmm='git check main && git pull origin main'
alias webstorm='open -na "WebStorm.app" --args nosplash "$@"'
alias i='npm i -g @antfu/ni'
alias wb='webstorm .'
alias z='cursor ~/.zshrc'
alias b='bat ~/.zshrc'

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

function mq {
  mysql.server start
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

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# fulutter

export PATH=$PATH:/Users/miwanoshuntarou/development/flutter/bin

# use rbenv

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# exaの時のディレクトリ表示カスタマイズ

if [[ $(command -v exa) ]]; then
  alias e='exa --icons'
  alias l=e
  alias ls=e
  alias ea='exa -a --icons'
  alias la=ea
  alias ee='exa -aal --icons'
  alias ll=ee
  alias et='exa -T -L 3 -a -I "node_modules|.git|.cache" --icons'
  alias lt=et
  alias eta='exa -T -a -I "node_modules|.git|.cache" --color=always --icons | less -r'
  alias lta=eta
fi

# startship
eval "$(starship init zsh)"%
