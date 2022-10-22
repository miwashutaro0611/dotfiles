# peco
function peco-history-selection() {
  BUFFER=`history -n 1 | tail -r  | awk '!a[$0]++' | peco`
  CURSOR=$#BUFFER
  zle reset-prompt
}

zle -N peco-history-selection
bindkey '^R' peco-history-selection

# nodenv
export PATH="$HOME/.nodenv/bin:$PATH"
eval "$(nodenv init -)"

# alias
alias ga='git add -A'
alias gc='git commit -m'
alias gca='git commit --amend'
alias gbr='git branch'
alias gac='git add -A && git commit -m'
alias gchb='git checkout -b'
alias gch='git checkout'
alias gst='git status'
alias gs='git stash'
alias g='git'
alias y='yarn'
alias yd='yarn dev'
alias yt='yarn test'
alias yb='yarn build'
alias yl='yarn lint'
alias n='npm'
alias ni='npm i'
alias ns='npm run start'
alias nb='npm run build'
alias nt='npm run test'
alias nl='npm run lint'
alias gd='git pull origin develop'
alias gm='git pull origin main'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias t='touch'
alias mk='mkdir'

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

# zsh-autosuggestions
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# 現在のブランチをプッシュ
function gu() {
  BRANCH=$(git symbolic-ref --short HEAD | tr -d '\n') # カレントブランチ名を取得
  git push origin $BRANCH
}

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