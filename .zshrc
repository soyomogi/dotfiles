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
alias gfre='git fetch origin && git remote prune origin'
alias gpc='git push --set-upstream origin "$(git branch --contains | cut -d " " -f 2)"'
alias gpp='git pull origin "$(git branch --contains | cut -d " " -f 2)" && git push origin "$(git branch --contains | cut -d " " -f 2)"'

get_obsidian_workspace() {
  # 環境に合わせてobsidianのworkspaces.jsonへのパスを設定
  WORKSPACES_JSON="${OBSIDIAN_ROOT}/.obsidian/workspaces.json"

  # ファイルが存在するか確認
  if [ -f "$WORKSPACES_JSON" ]; then
    # jqを使ってactiveなワークスペース名を抽出
    if command -v jq &> /dev/null; then
      WORKSPACE=$(jq -r '.active' "$WORKSPACES_JSON" 2>/dev/null)
      echo "$WORKSPACE"
    else
      # jqがない場合はgrepとsedで抽出を試みる
      WORKSPACE=$(grep -o '"active[[:space:]]*:[[:space:]]*"[^"]*"' "$WORKSPACES_JSON" | sed 's/"active"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/')
      echo "$WORKSPACE"
    fi
  else
    echo "unknown"
  fi
}

# auto tmux (obsidian)
if [[ "$__CFBundleIdentifier" == "md.obsidian" ]]; then
  # Check if we are already in a tmux session
  if [ -z "$TMUX" ]; then
    source ~/.zprofile
    SESSION_NAME=$(get_obsidian_workspace)
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
      tmux attach-session -t "$SESSION_NAME"
    else
      tmux new-session -s "$SESSION_NAME" -c ~
    fi
  fi
fi

# starship
eval "$(starship init zsh)"
