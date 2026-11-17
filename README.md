# dotfiles

基本設定の配置:

```sh
bash init.sh
```

Obsidian プラグインとスニペットも配置する場合は、実行時に `OBSIDIAN_ROOT` に Vault のルートを指定する。

skillshare の設定とスキルの復元・同期:

```sh
python3 scripts/setup-skillshare.py --install
```

Python 3.9 以降と skillshare が必要。配置だけなら `--install` を省略する。
自作スキルは別途 `soyomogi/skills` を `~/git/skills` に用意し、そこで `apm install --target codex` を実行しておく。
