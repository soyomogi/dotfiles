#!/usr/bin/env bash
set -eu

# ====== 設定 ======
GITDIR="${GITDIR:-"$HOME/git/dotfiles"}"

# 置き場
CFG="$HOME/.config"
NVIM="$CFG/nvim"
LGIT="$CFG/lazygit"
STARSHIP="$CFG/starship.toml"
HERDR="$CFG/herdr"
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

# link_keep <dst> <src>
# 既存ファイルはバックアップへ退避してからリンクする。
OBS_BAK=
link_keep() {
  if [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; then
    return
  fi
  if [ -e "$1" ] || [ -L "$1" ]; then
    if [ -z "$OBS_BAK" ]; then
      OBS_BAK=$(mktemp -d "$OBS_CFG/.dotfiles-backup.XXXXXX")
      printf 'backup: %s\n' "$OBS_BAK"
    fi
    mv "$1" "$OBS_BAK/$(basename "$1")"
  fi
  mkdir -p "$(dirname "$1")"
  ln -s "$2" "$1"
  printf 'link: %s -> %s\n' "$1" "$2"
}

# ====== 実行 ======
# zsh / vim / screen / tmux
link "$HOME/.zshrc" "$GITDIR/.zshrc"
link "$HOME/.vimrc" "$GITDIR/.vimrc"
link "$HOME/.screenrc" "$GITDIR/.screenrc"
link "$HOME/.tmux.conf" "$GITDIR/.tmux.conf"

# neovim / lazygit / starship / herdr
link "$NVIM" "$GITDIR/.config/nvim"
link "$LGIT" "$GITDIR/.config/lazygit"
link "$STARSHIP" "$GITDIR/.config/starship.toml"
link "$HERDR/config.toml" "$GITDIR/.config/herdr/config.toml"

# vim カラースキーム
mkdir -p "$VCOL"
fetch_if_missing "https://raw.githubusercontent.com/tomasr/molokai/master/colors/molokai.vim" \
  "$VCOL/molokai.vim"
fetch_if_missing "https://raw.githubusercontent.com/tssm/fairyfloss.vim/master/colors/fairyfloss.vim" \
  "$VCOL/fairyfloss.vim"

# Obsidian plugin and custom CSS. The vault root comes from
# $OBSIDIAN_ROOT; unset means this machine has no deployment.
if [ -n "${OBSIDIAN_ROOT:-}" ] && [ -d "$OBSIDIAN_ROOT/.obsidian" ]; then
  OBS_CFG="$OBSIDIAN_ROOT/.obsidian"
  link_keep "$OBS_CFG/plugins/skillshare-ui" "$GITDIR/obsidian/plugins/skillshare-ui"
  link_keep "$OBS_CFG/snippets/soyomogi.css" "$GITDIR/obsidian/snippets/soyomogi.css"
else
  printf 'skip: OBSIDIAN_ROOT is not set to an Obsidian vault\n'
fi

printf 'done\n'
