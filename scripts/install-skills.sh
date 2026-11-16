#!/usr/bin/env bash
set -eu

if ! command -v skillshare >/dev/null 2>&1; then
  printf 'skip: skillshare is not installed\n'
  exit 0
fi

GITDIR="${GITDIR:-"$(cd "$(dirname "$0")/.." && pwd)"}"
bash "$GITDIR/scripts/setup-skillshare.sh" "$GITDIR"

# Restore the reviewed selection at the recorded revisions, retaining auditing.
while IFS="$(printf '\t')" read -r repository revision skills; do
  case "$repository" in ''|'#'*) continue ;; esac
  skillshare install "$repository" --branch "$revision" --skill "$skills" --update -g
done < "$GITDIR/.config/skillshare/skills.tsv"

# APM and the author's checkout are prepared independently in ~/git/skills.
apm_source="$HOME/git/skills/.agents/skills"
apm_link="$HOME/.config/skillshare/skills/_apm"
if [ -d "$apm_source" ]; then
  if [ -e "$apm_link" ] || [ -L "$apm_link" ]; then
    if [ ! -d "$apm_link" ] || [ "$(cd "$apm_link" && pwd -P)" != "$(cd "$apm_source" && pwd -P)" ]; then
      printf 'error: %s already points elsewhere\n' "$apm_link" >&2
      exit 1
    fi
  else
    skillshare link "$apm_source" --name _apm -g
  fi
else
  printf 'skip: APM skills are not prepared in ~/git/skills/.agents/skills\n'
fi

skillshare sync -g
skillshare sync extras -g
