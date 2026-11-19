source ~/.zprofile

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
zinit snippet PZTM::helper
zinit snippet PZTM::utility
zinit snippet PZT::modules/git/alias.zsh

# screen
export SCREENDIR=$HOME/.screen

# change ls colors
alias ls="ls -G"
export LSCOLORS=exfxcxdxbxegedabagacad

# my alias
alias lg='lazygit'
alias gfre='git fetch origin && git remote prune origin'
alias gpc='git push --set-upstream origin "$(git branch --contains | cut -d " " -f 2)"'
alias gpp='git pull origin "$(git branch --contains | cut -d " " -f 2)" && git push origin "$(git branch --contains | cut -d " " -f 2)"'
alias gsfm='git submodule update --init --remote'

# Obsidian Terminal 内でのみ Herdr を自動起動し、未導入なら tmux を使う
# WSL では TERM_PROGRAM が渡らないため、専用フラグも確認する。
if [[ ( "$TERM_PROGRAM" == "obsidian-terminal" || "$OBSIDIAN_TERMINAL" == "true" ) && -z "$HERDR_ENV" && -z "$TMUX" ]]; then
  if command -v herdr &> /dev/null; then
    herdr
  elif command -v tmux &> /dev/null; then
    tmux new-session -A -s main
  fi
fi

# herdr tab / pane context
function _herdr_refresh_context() {
  [[ -n "$HERDR_PANE_ID" ]] || return 0
  command -v herdr &> /dev/null && command -v jq &> /dev/null || return 0

  local pane_info
  pane_info=$(herdr pane get "$HERDR_PANE_ID" 2>/dev/null) || return 0
  export HERDR_TAB_ID=$(print -r -- "$pane_info" | jq -r '.result.pane.tab_id // ""' 2>/dev/null)
  export HERDR_PANE_NAME=$(print -r -- "$pane_info" | jq -r '.result.pane.label // ""' 2>/dev/null)
  export HERDR_TAB_NAME=""
  if [[ -n "$HERDR_TAB_ID" ]]; then
    HERDR_TAB_NAME=$(herdr tab get "$HERDR_TAB_ID" 2>/dev/null | jq -r '.result.tab.label // ""' 2>/dev/null)
  fi
  return 0
}
_herdr_refresh_context
# .zshrc の再読み込み時にも古いフックや重複を残さない
precmd_functions=(${precmd_functions:#_herdr_refresh_tab_name})
precmd_functions=(${precmd_functions:#_herdr_refresh_context})
precmd_functions+=(_herdr_refresh_context)

# starship
eval "$(starship init zsh)"
