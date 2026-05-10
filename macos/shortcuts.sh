#!/usr/bin/env bash
# macos/shortcuts.sh — apply preferred macOS keyboard shortcuts.
#
# - Sleep:  Apple メニューの「スリープ」項目に独自ショートカットを割り当てる
#           (NSUserKeyEquivalents)
# - Mission Control / Spaces / Show Desktop など:
#           com.apple.symbolichotkeys を直接書き換え
#
# 修飾キーフラグ (10 進):
#   Cmd     = 1048576   (0x100000)
#   Shift   = 131072    (0x020000)
#   Ctrl    = 262144    (0x040000)
#   Option  = 524288    (0x080000)
#   Fnキー  = 8388608   (0x800000)
#   組合せ  = 上記の bitwise OR (例: Ctrl+Shift = 393216)
#
# NSUserKeyEquivalents の文字列表記:
#   @ = Cmd, ^ = Ctrl, ~ = Option, $ = Shift
#   例: "@^$s" = Cmd+Ctrl+Shift+S

set -euo pipefail

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is for macOS only." >&2
  exit 1
fi

echo "Applying keyboard shortcuts..."

# ============================================================
# 1. Sleep — Apple メニューの「スリープ」を Cmd+Ctrl+Option+S に割り当て
# ============================================================
# システム設定 > キーボード > キーボードショートカット > アプリケーション
# でも同じ設定が GUI で確認できる。
defaults write -g NSUserKeyEquivalents -dict-add "Sleep"          "@^~s"
defaults write -g NSUserKeyEquivalents -dict-add "スリープ"         "@^~s"

# ============================================================
# 2. Mission Control / Spaces / Window arrangement
#    — com.apple.symbolichotkeys を書き換え
# ============================================================
# parameters = ( <ASCII char or 65535>, <virtual keycode>, <modifier flags> )
# 主要キーコード:
#   space=49 / left=123 / right=124 / down=125 / up=126
#   F3=160 / F11=103 / F12=111
#   1=18 / 2=19 / 3=20 / 4=21 / 5=23 / 6=22

set_hotkey() {
  local id="$1" enabled="$2" param1="$3" param2="$4" param3="$5"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$id" \
    "{enabled = $enabled; value = { parameters = ($param1, $param2, $param3); type = 'standard'; }; }"
}

# Mission Control: Ctrl+Up (デフォルト維持)
set_hotkey 32 1 65535 126 262144

# Application windows: Ctrl+Down (デフォルト維持)
set_hotkey 33 1 65535 125 262144

# Show Desktop (デスクトップを表示): F11
set_hotkey 36 1 65535 103 8388608

# Move left a space: Ctrl+Left
set_hotkey 79 1 65535 123 262144
set_hotkey 80 1 65535 123 393216  # Ctrl+Shift+Left

# Move right a space: Ctrl+Right
set_hotkey 81 1 65535 124 262144
set_hotkey 82 1 65535 124 393216  # Ctrl+Shift+Right

# Switch to Desktop 1..3: Ctrl+1 / Ctrl+2 / Ctrl+3
set_hotkey 118 1 49 18 262144
set_hotkey 119 1 50 19 262144
set_hotkey 120 1 51 20 262144

# ============================================================
# 3. 反映
# ============================================================
# symbolichotkeys は cfprefsd 経由でキャッシュされるため、即時反映には
# 以下のリロードが必要 (ログアウトでも反映される)。
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true

echo "Done. NSUserKeyEquivalents の変更は新しく起動するアプリから有効になります。"
echo "既存アプリは再起動するか、ログアウトしてから反映されます。"
