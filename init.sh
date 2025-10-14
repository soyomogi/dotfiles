#!/usr/bin/env bash
set -eu

# ====== 設定 ======
GITDIR="${GITDIR:-"$HOME/git/dotfiles"}"

# 置き場
CFG="$HOME/.config"
NVIM="$CFG/nvim"
LGIT="$CFG/lazygit"
VIM="$HOME/.vim"
VCOL="$VIM/colors"

# ====== 関数 ======
# link <dst> <src>
link() {
  rm -rf "$1"
  mkdir -p "$(dirname "$1")"
  ln -s "$2" "$1"
  printf 'link: %s -> %s\n' "$1" "$2"
}

# fetch_if_missing <url> <dst>
fetch_if_missing() {
  [ -e "$2" ] && return 0
  mkdir -p "$(dirname "$2")"
  curl -fsSL "$1" -o "$2"
  printf 'get : %s\n' "$2"
}

# ====== 実行 ======
# zsh / vim / screen / tmux
link "$HOME/.zshrc" "$GITDIR/.zshrc"
link "$HOME/.vimrc" "$GITDIR/.vimrc"
link "$HOME/.screenrc" "$GITDIR/.screenrc"
link "$HOME/.tmux.conf" "$GITDIR/.tmux.conf"

# neovim / lazygit
link "$NVIM" "$GITDIR/.config/nvim"
link "$LGIT" "$GITDIR/.config/lazygit"

# vim カラースキーム
mkdir -p "$VCOL"
fetch_if_missing "https://raw.githubusercontent.com/tomasr/molokai/master/colors/molokai.vim" \
  "$VCOL/molokai.vim"
fetch_if_missing "https://raw.githubusercontent.com/tssm/fairyfloss.vim/master/colors/fairyfloss.vim" \
  "$VCOL/fairyfloss.vim"

printf 'done\n'
