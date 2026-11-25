#!/bin/sh
set -eu

herdr_bin=${HERDR_BIN_PATH:-herdr}
plugin=$("$herdr_bin" plugin list --plugin herdr-file-viewer --json |
  jq -er '.result.plugins[] | select(.enabled) | .plugin_root')

# Keep the viewer's launch/focus/close behavior and choose the split direction here.
panes=$("$herdr_bin" pane list)
decision=$(printf '%s\n' "$panes" | "$plugin/target/release/herdr-file-viewer" --launch-decision)
case "$decision" in
  "FOCUS "*) exec "$herdr_bin" plugin pane focus "${decision#FOCUS }" ;;
  "CLOSE "*) exec "$herdr_bin" plugin pane close "${decision#CLOSE }" ;;
  OPEN) ;;
  *) printf 'Unexpected Files launch decision: %s\n' "$decision" >&2; exit 1 ;;
esac

result=$("$herdr_bin" plugin pane open --plugin herdr-file-viewer --entrypoint file-viewer \
  --placement split --direction right --focus)
files_pane=$(printf '%s\n' "$result" | jq -er '.result.plugin_pane.pane.pane_id')

layout=$("$herdr_bin" pane layout --pane "$files_pane")
resize=$(printf '%s\n' "$layout" | jq -r --arg pane "$files_pane" '
  .result.layout.panes as $panes
  | ($panes[] | select(.pane_id == $pane).rect) as $files
  | select($files.width > 40)
  | $panes[]
  | select(.rect.y == $files.y and .rect.height == $files.height
    and (.rect.x + .rect.width) == $files.x)
  | [.pane_id, (($files.width - 40) / (.rect.width + $files.width))]
  | @tsv
')
[ -n "$resize" ] || exit 0
read -r left_pane amount <<EOF
$resize
EOF
"$herdr_bin" pane resize --pane "$left_pane" --direction right --amount "$amount"
