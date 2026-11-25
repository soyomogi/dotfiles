# dotfiles

## 事前準備

Herdr TUI の Files と自動改名を使う場合は、`jq` を用意してプラグインを入れる。

```sh
herdr plugin install smarzban/herdr-file-viewer
herdr plugin install qu8n/herdr-automatic-rename
```

Herdr App の `soyomogi` レイアウトを使うには、Herdsidian と skillshare の mod を別途導入する。

## 基本設定の配置

```sh
bash init.sh
```

Obsidian プラグインとスニペットも配置する場合は、実行時に `OBSIDIAN_ROOT` に Vault のルートを指定する。

macOS では、Herdr App の初回起動前にも `soyomogi` レイアウトとキー設定を配置できる。

Terminal プラグインが入っている Vault には、`.obsidian/plugins/terminal/keymappings.json` の割り当ても配置する。Obsidian を終了してから `init.sh` を実行するか、開いている Vault には Obsidian CLI で反映する。

```sh
python3 scripts/setup-obsidian-terminal.py --live "$OBSIDIAN_ROOT"
```

Herdr TUI で `Ctrl+B` → `f` を押すと、Files が右側に約40列の分割ペインで開く。新しく開く zsh では、コマンドの開始・終了時にタブ名を更新する。

## skillshare の設定とスキルの復元・同期

Python と skillshare が必要。自作スキルは `soyomogi/skills` を `~/git/skills` に用意してから配置する。

```sh
(cd ~/git/skills && apm install --target codex)
```

```sh
python3 scripts/setup-skillshare.py --install
```

配置だけなら `--install` を省略する。
