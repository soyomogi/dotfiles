### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

# コマンド履歴の管理
HISTFILE=~/.zsh_history
export HISTSIZE=1000
export SAVEHIST=10000

# screen デタッチした場合にもssh agent forwardingを有効にする
AUTH_SOCK="$HOME/.ssh/.ssh-auth-sock"
if [ -S "$AUTH_SOCK" ]; then
  export SSH_AUTH_SOCK=$AUTH_SOCK
elif [ ! -S "$SSH_AUTH_SOCK" ]; then
  export SSH_AUTH_SOCK=$AUTH_SOCK
elif [ ! -L "$SSH_AUTH_SOCK" ]; then
  ln -snf "$SSH_AUTH_SOCK" $AUTH_SOCK && export SSH_AUTH_SOCK=$AUTH_SOCK
fi

## コマンド補完
zinit ice wait'0'; zinit light zsh-users/zsh-completions
autoload -Uz compinit && compinit

## 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

## 補完候補を一覧表示したとき、Tabや矢印で選択できるようにする
zstyle ':completion:*:default' menu select=1 

## シンタックスハイライト
zinit light zsh-users/zsh-syntax-highlighting

## 履歴補完
zinit light zsh-users/zsh-autosuggestions

## 先人の知恵
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet PZTM::helper
zinit snippet PZTM::utility

# screen
export SCREENDIR=$HOME/.screen

# change ls colors
export LSCOLORS=exfxcxdxbxegedabagacad

# my alias
alias gfre='git fetch origin && git remote prune origin'

# auto tmux
if [[ ! -n $TMUX && $- == *l* ]]; then
  # get the IDs
  ID="`tmux list-sessions`"
  if [[ -z "$ID" ]]; then
    tmux new-session
  fi
  create_new_session="Create New Session"
  ID="$ID\n${create_new_session}:"
  ID="`echo $ID | $PERCOL | cut -d: -f1`"
  if [[ "$ID" = "${create_new_session}" ]]; then
    tmux new-session
  elif [[ -n "$ID" ]]; then
    tmux attach-session -t "$ID"
  else
    :  # Start terminal normally
  fi
fi

# starship
eval "$(starship init zsh)"
