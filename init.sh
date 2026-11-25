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
HERDR_APP="$CFG/herdr-app"
GIT_CONFIG="$CFG/git/config"
VIM="$HOME/.vim"
VCOL="$VIM/colors"

# ====== 関数 ======
# link <dst> <src>
link() {
  if [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; then
    return 0
  fi
  rm -rf "$1"
  mkdir -p "$(dirname "$1")"
  ln -s "$2" "$1"
  printf 'link: %s -> %s\n' "$1" "$2"
}

# link_with_backup <dst> <src>
link_with_backup() {
  local backup
  if [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; then
    return 0
  fi
  if { [ -e "$1" ] || [ -L "$1" ]; } && ! cmp -s "$1" "$2"; then
    backup=$(mktemp -d "$1.backup.XXXXXX")
    mv "$1" "$backup/"
    printf 'saved: %s/%s\n' "$backup" "$(basename "$1")"
  fi
  link "$1" "$2"
}

# fetch_if_missing <url> <dst>
fetch_if_missing() {
  [ -e "$2" ] && return 0
  mkdir -p "$(dirname "$2")"
  curl -fsSL "$1" -o "$2"
  printf 'get : %s\n' "$2"
}

# copy <dst> <src>
copy() {
  rm -rf "$1"
  mkdir -p "$(dirname "$1")"
  cp -R "$2" "$1"
  printf 'copy: %s -> %s\n' "$2" "$1"
}

# ====== 実行 ======
# Windows のホームにも同じ git 置き場を公開する。
if [ "${OS:-}" = 'Windows_NT' ] || [ -n "${WSL_DISTRO_NAME:-}" ]; then
  GIT_ROOT=$(cd "$GITDIR/.." && pwd -P)
  if [ -n "${WSL_DISTRO_NAME:-}" ]; then
    WINDOWS_GIT_ROOT=$(wslpath -w "$GIT_ROOT")
  else
    WINDOWS_GIT_ROOT=$(cygpath -w "$GIT_ROOT")
  fi
  printf '%s\n' "$WINDOWS_GIT_ROOT" | powershell.exe -NoProfile -NonInteractive -Command '
    $ErrorActionPreference = "Stop"
    [Console]::InputEncoding = [Text.UTF8Encoding]::new()
    $source = [Console]::In.ReadLine()
    $destination = Join-Path $env:USERPROFILE "git"
    $existing = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
    if ($existing) {
      $target = if ($existing.LinkType) { @($existing.Target)[0] } else { $existing.FullName }
      if (![IO.Path]::IsPathRooted($target)) { $target = Join-Path $env:USERPROFILE $target }
      if ([IO.Path]::GetFullPath($target) -ne [IO.Path]::GetFullPath($source)) {
        throw "Existing git path points elsewhere: $destination"
      }
    } else {
      New-Item -ItemType Junction -Path $destination -Target $source | Out-Null
      Write-Host "link: $destination -> $source"
    }
  '
fi

# zsh / vim / screen / tmux
link "$HOME/.zshrc" "$GITDIR/.zshrc"
link "$HOME/.vimrc" "$GITDIR/.vimrc"
link "$HOME/.screenrc" "$GITDIR/.screenrc"
link "$HOME/.tmux.conf" "$GITDIR/.tmux.conf"

# neovim / lazygit / starship / herdr / git
link "$NVIM" "$GITDIR/.config/nvim"
link "$LGIT" "$GITDIR/.config/lazygit"
link "$STARSHIP" "$GITDIR/.config/starship.toml"
link "$HERDR/config.toml" "$GITDIR/.config/herdr/config.toml"
link "$HERDR/open-files.sh" "$GITDIR/.config/herdr/open-files.sh"
link "${XDG_CONFIG_HOME:-$CFG}/herdr-automatic-rename/config.sh" \
  "$GITDIR/.config/herdr-automatic-rename/config.sh"
link "$GIT_CONFIG" "$GITDIR/.config/git/config"

# The App keymap uses macOS shortcuts.
if [ "$(uname -s)" = Darwin ]; then
  APP_SOURCE="$GITDIR/.config/herdr-app"
  for mod in tui-prefix files-shortcut; do
    link_with_backup "$HERDR_APP/mods/$mod/main.js" "$APP_SOURCE/mods/$mod/main.js"
    link_with_backup "$HERDR_APP/mods/$mod/mod.json" "$APP_SOURCE/mods/$mod/mod.json"
  done
  link "$HERDR_APP/layouts/soyomogi.json" "$APP_SOURCE/layouts/soyomogi.json"
  link "$HERDR_APP/themes/pink.json" "$APP_SOURCE/themes/pink.json"
  link "$HERDR_APP/keys.json" "$APP_SOURCE/keys.json"
fi

# vim カラースキーム
mkdir -p "$VCOL"
fetch_if_missing "https://raw.githubusercontent.com/tomasr/molokai/master/colors/molokai.vim" \
  "$VCOL/molokai.vim"
fetch_if_missing "https://raw.githubusercontent.com/tssm/fairyfloss.vim/master/colors/fairyfloss.vim" \
  "$VCOL/fairyfloss.vim"

# Obsidian plugin, custom CSS, and Terminal key mappings. The vault root comes from
# $OBSIDIAN_ROOT; unset means this machine has no deployment.
if [ -n "${OBSIDIAN_ROOT:-}" ] && [ -d "$OBSIDIAN_ROOT/.obsidian" ]; then
  OBS_CFG="$OBSIDIAN_ROOT/.obsidian"
  copy "$OBS_CFG/plugins/skillshare-ui" "$GITDIR/.obsidian/plugins/skillshare-ui"
  copy "$OBS_CFG/snippets/soyomogi.css" "$GITDIR/.obsidian/snippets/soyomogi.css"
  if [ -f "$OBS_CFG/plugins/terminal/manifest.json" ]; then
    python3 "$GITDIR/scripts/setup-obsidian-terminal.py" "$OBSIDIAN_ROOT"
  fi
else
  printf 'skip: OBSIDIAN_ROOT is not set to an Obsidian vault\n'
fi

printf 'done\n'
