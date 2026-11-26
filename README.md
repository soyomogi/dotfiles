# dotfiles

## 基本設定

```sh
bash init.sh
```

Obsidian プラグインとスニペットを配置する場合は、`OBSIDIAN_ROOT` に Vault のルートを指定して実行する。Terminal プラグインのキー設定も反映する場合は、Obsidian を終了してから実行する。Obsidian を開いたまま Terminal のキー設定だけを反映する場合は、次を実行する。

```sh
python3 scripts/setup-obsidian-terminal.py --live "$OBSIDIAN_ROOT"
```

## Herdr

Herdr TUI の Files とタブの自動改名を使う場合は、`jq` と次のプラグインをインストールする。

```sh
herdr plugin install smarzban/herdr-file-viewer
herdr plugin install qu8n/herdr-automatic-rename
```

Files は `Ctrl+B` → `f` で開く。設定を適用した zsh はコマンドの開始・終了時にタブ名を更新する。

macOS では `init.sh` が Herdr App のレイアウトとキー設定も配置する。`soyomogi` レイアウトには Herdsidian と skillshare の mod が必要。

## skillshare の設定と同期

skillshare をインストールする。自作スキルを同期する場合は `soyomogi/skills` を `~/git/skills` にクローンする。セットアップは `~/git/skills/skills` を同期元にする。既存の `soyomogi` リンクが旧 APM 展開先の `~/git/skills/.agents/skills`を指している場合は、実行時に付け替える。

macOS・Linux・Termux・WSL では Python 版を実行する。

```sh
python3 scripts/setup-skillshare.py --install
```

Windows の PowerShell では Windows 版を実行する。

```powershell
.\scripts\setup-skillshare-windows.ps1 -Install
```

設定の配置だけ行う場合は、`--install` または `-Install` を省く。セットアップは `copy` モードでスキルを同期し、extras を配布先のコピーに適用する。自作スキルの編集後は次の順で同期する。

```sh
skillshare sync -g
skillshare sync extras -g
```
