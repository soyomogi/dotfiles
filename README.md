# dotfiles

基本設定の配置:

```sh
bash init.sh
```

Obsidian プラグインとスニペットも配置する場合は、実行時に `OBSIDIAN_ROOT` に Vault のルートを指定する。

skillshare の設定・Chrome 拡張の配置とスキルの復元・同期:

```sh
python3 scripts/setup-skillshare.py --install
```

Python 3.9 以降と skillshare が必要。配置だけなら `--install` を省略する。
自作スキルは別途 `soyomogi/skills` を `~/git/skills` に用意し、そこで `apm install --target codex` を実行しておく。
Chrome 拡張は `~/.config/skillshare/ui` を読み込む。詳細は [拡張の README](extensions/skillshare-ui-pink-theme/README.md) を参照。

検証:

```sh
python3 -m unittest discover -s tests -v
```
