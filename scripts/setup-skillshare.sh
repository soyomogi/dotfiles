#!/usr/bin/env bash
set -eu

GITDIR="${1:-${GITDIR:-"$HOME/git/dotfiles"}}"
shared="$GITDIR/.config/skillshare"
local_root="$HOME/.config/skillshare"
backup_dir=

# Keep installed skills, metadata and private memory outside dotfiles.
# Preserve existing files before replacing them with managed links.
link_shared() {
  local source="$1" target="$2"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    return
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -z "$backup_dir" ]; then
      backup_dir=$(mktemp -d "$local_root/.dotfiles-backup.XXXXXX")
      printf 'backup: %s\n' "$backup_dir"
    fi
    mv "$target" "$backup_dir/$(basename "$target")"
  fi
  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
  printf 'link: %s -> %s\n' "$target" "$source"
}

mkdir -p "$local_root/skills" "$local_root/extras"

# The ui directory is assembled from links. theme.css is canonical
# with the Obsidian plugin and linked in like the extension files.
ui_root="$local_root/ui"
if [ -L "$ui_root" ]; then
  rm "$ui_root"
fi
mkdir -p "$ui_root"
link_shared "$shared/ui/manifest.json" "$ui_root/manifest.json"
link_shared "$shared/ui/README.md" "$ui_root/README.md"
link_shared "$shared/ui/LICENSE" "$ui_root/LICENSE"
link_shared "$GITDIR/obsidian/plugins/skillshare-ui/theme.css" "$ui_root/theme.css"

link_shared "$shared/config.yaml" "$local_root/config.yaml"
link_shared "$shared/.skillignore" "$local_root/skills/.skillignore"
link_shared "$shared/extras/soyomogi" "$local_root/extras/soyomogi"

printf 'skillshare configuration ready; install/sync separately with scripts/install-skills.sh\n'
