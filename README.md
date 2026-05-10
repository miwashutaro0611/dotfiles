# dotfiles

シンボリックリンクで管理する個人用 macOS 設定ファイル群。

## クイックスタート (新規マシン)

```bash
git clone <this-repo> ~/code/dotfiles
cd ~/code/dotfiles
./bootstrap.sh
```

`bootstrap.sh` は Homebrew + パッケージ、Oh My Zsh をインストールしたあと `install.sh` を実行します。

## スクリプト一覧

| スクリプト | 役割 |
|---|---|
| `bootstrap.sh` | 新規マシンのワンショットセットアップ。冪等に再実行可能。 |
| `install.sh` | リポジトリ内のファイルを `$HOME` にシンボリックリンク **+** 外部リポジトリ (`zsh-autosuggestions` 等) を自動 clone。何度でも再実行可。 |
| `install.sh --dry-run` | 実際に書き込まずに、何が起こるかだけ表示。 |
| `macos/defaults.sh` | macOS のシステム設定 (Finder / Dock / キーボード) を適用。 |

### `install.sh` が clone する外部リポジトリ

`.zshrc` から `source` しているが dotfiles 本体ではないものは、`install.sh` 冒頭の `EXTERNAL_REPOS` 配列に列挙されています。

| リポジトリ | clone 先 |
|---|---|
| `zsh-users/zsh-autosuggestions` | `~/.zsh/zsh-autosuggestions` |

新たに依存リポジトリを追加したい場合は `EXTERNAL_REPOS` に `"<git-url>::<target-path>"` 形式で1行追記するだけです。

## 管理対象ファイル

| リポジトリ内のパス | リンク先 (`$HOME` 配下) |
|---|---|
| `zsh/.zshrc` `.zshenv` `.zprofile` | `~/.zshrc` ほか |
| `git/.gitconfig` `.gitignore_global` | `~/.gitconfig` ほか |
| `claude/{settings.json, statusline.py, ..., agents/}` | `~/.claude/...` |
| `codex/config.toml` | `~/.codex/config.toml` |
| `gemini/settings.json` | `~/.gemini/settings.json` |
| `ai/AGENTS.md` | `~/AGENTS.md` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `cursor/{settings,keybindings}.json` | `~/Library/Application Support/Cursor/User/...` |

## Git: 個人情報の分離

`git/.gitconfig` は末尾で `include.path = ~/.gitconfig.local` を読み込む構成です。テンプレートからローカル設定ファイルを作成してください:

```bash
cp git/.gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local   # user.name / user.email を設定
```

`*.local` は `.gitignore` で除外されているため、氏名やメールアドレスがリポジトリに含まれる心配はありません。

## 新しい dotfile を追加するには

1. 対応する種類のサブディレクトリにファイルを配置する
2. `install.sh` の `LINKS` 配列にエントリを追加する
3. `./install.sh` を実行する

## バックアップ

`install.sh` はリンク作成前に、既存の非 symlink ファイルを `~/.dotfiles_backup/<timestamp>/` に退避します。サイレントに上書きされることはありません。

## 管理しないもの (意図的に除外)

- 認証情報を含むファイル (`auth.json`, `oauth_creds.json`, `.env` など)
- ランタイムデータ (`sessions/`, `history.jsonl`, `cache/`, sqlite ログ など)
- マシン固有 / プロジェクト固有のエントリ (codex `config.toml` 内の `[projects.*]` など)
- `~/.claude/skills/` (ツール側で動的に管理されるため)
