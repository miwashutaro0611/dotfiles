#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd')
model_id=$(echo "$input" | jq -r '.model.id // empty')
model_display=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')


# カレントディレクトリを ~ に短縮
home="$HOME"
display_cwd=$(echo "$cwd" | sed "s|^$home|~|")

# Git リポジトリ名とブランチ名を取得
repo_name=""
branch=""
pr_number=""
git_diff_stat=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  repo_name=$(basename "$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)

  # git diff の変更統計を取得（staged + unstaged）
  diff_stat=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" diff --numstat 2>/dev/null)
  staged_stat=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" diff --cached --numstat 2>/dev/null)
  combined_stat=$(printf "%s\n%s" "$diff_stat" "$staged_stat" | grep -v '^$')
  if [ -n "$combined_stat" ]; then
    added=$(printf "%s" "$combined_stat" | awk '{a+=$1} END{print a+0}')
    changed=$(printf "%s" "$combined_stat" | awk 'NR>0{c++} END{print c+0}')
    [ "$added" -gt 0 ] && git_diff_stat="+${added}"
    [ "$changed" -gt 0 ] && git_diff_stat="${git_diff_stat:+$git_diff_stat }~${changed}"
  fi

  # PR 番号を取得（gh コマンドがある場合のみ、open 状態の最初の1件に限定）
  if command -v gh > /dev/null 2>&1 && [ -n "$branch" ]; then
    pr_number=$(GIT_OPTIONAL_LOCKS=0 gh pr list --head "$branch" --state open --json number --jq '.[0].number' -R "$(git -C "$cwd" remote get-url origin 2>/dev/null)" 2>/dev/null)
  fi
fi

# モデル ID を短縮表示（例: claude-sonnet-4-6-20250514 → claude-sonnet-4-6）
model_short=""
if [ -n "$model_id" ] && [ "$model_id" != "null" ]; then
  model_short=$(echo "$model_id" | sed 's/-[0-9]\{8\}$//')
fi

# コンテキスト使用率バー
context_line=""
if [ -n "$used" ] && [ "$used" != "null" ]; then
  used_int=$(printf "%.0f" "$used")
  bar_total=20
  bar_filled=$(( used_int * bar_total / 100 ))
  bar_empty=$(( bar_total - bar_filled ))
  bar=""
  i=0
  while [ $i -lt $bar_filled ]; do
    bar="${bar}█"
    i=$(( i + 1 ))
  done
  i=0
  while [ $i -lt $bar_empty ]; do
    bar="${bar}░"
    i=$(( i + 1 ))
  done
  context_line="🧠 ${bar} ${used_int}%"
  if [ -n "$model_short" ]; then
    context_line="${context_line} │ 💪 ${model_short}"
  fi
fi

# コスト使用率（キャッシュファイルで累積トークンを追跡）
cost_line=""
cache_dir="$HOME/.claude/statusline-cache"
mkdir -p "$cache_dir"

now=$(date +%s)
cache_file="${cache_dir}/cost.json"

# モデル別のトークン単価（1M トークンあたりの USD）
get_price_per_1m() {
  mid="$1"
  case "$mid" in
    *opus-4*)    echo "15.0 75.0" ;;   # input $15 / output $75
    *sonnet-4*)  echo "3.0 15.0" ;;    # input $3  / output $15
    *haiku-3-5*) echo "0.8 4.0" ;;     # input $0.8 / output $4
    *haiku-3*)   echo "0.25 1.25" ;;   # input $0.25 / output $1.25
    *)           echo "3.0 15.0" ;;    # デフォルト sonnet 相当
  esac
}

# 現在のセッションの累積コストを概算
prices=$(get_price_per_1m "$model_id")
in_price=$(echo "$prices" | awk '{print $1}')
out_price=$(echo "$prices" | awk '{print $2}')
session_cost=$(echo "$total_input $total_output $in_price $out_price" | awk '{
  cost = ($1 / 1000000 * $3) + ($2 / 1000000 * $4);
  printf "%.6f", cost
}')

# キャッシュファイルを読み込み・更新
if [ -f "$cache_file" ]; then
  ts_5h=$(( now - 5 * 3600 ))
  ts_7d=$(( now - 7 * 24 * 3600 ))

  updated=$(jq --argjson now "$now" \
               --arg sid "$session_id" \
               --argjson cost "$session_cost" \
               --argjson ts_5h "$ts_5h" \
               --argjson ts_7d "$ts_7d" \
    '
    ($. | map(select(.session_id == $sid)) | length) as $exists |
    if $exists > 0 then
      map(if .session_id == $sid then . + {cost: $cost, ts: $now} else . end)
    else
      . + [{session_id: $sid, cost: $cost, ts: $now}]
    end |
    map(select(.ts >= $ts_7d))
    ' "$cache_file" 2>/dev/null)

  if [ -n "$updated" ]; then
    echo "$updated" > "$cache_file"

    cost_5h=$(echo "$updated" | jq --argjson ts_5h "$ts_5h" \
      '[.[] | select(.ts >= $ts_5h) | .cost] | add // 0' 2>/dev/null)
    cost_7d=$(echo "$updated" | jq '[.[].cost] | add // 0' 2>/dev/null)
    last_ts_5h=$(echo "$updated" | jq --argjson ts_5h "$ts_5h" \
      '[.[] | select(.ts >= $ts_5h)] | if length > 0 then max_by(.ts).ts else 0 end' 2>/dev/null)
    last_ts_7d=$(echo "$updated" | jq 'if length > 0 then max_by(.ts).ts else 0 end' 2>/dev/null)

    # Max プランの想定予算（5時間: $5, 7日: $100 を基準）
    pct_5h=$(echo "$cost_5h" | awk '{printf "%.1f", $1 / 5.0 * 100}')
    pct_7d=$(echo "$cost_7d" | awk '{printf "%.1f", $1 / 100.0 * 100}')

    if [ "$last_ts_5h" != "0" ] && [ "$last_ts_5h" != "null" ] && [ -n "$last_ts_5h" ]; then
      # 時刻を "4am" / "3:30pm" 形式に変換
      hour_5h=$(date -r "$last_ts_5h" "+%-H" 2>/dev/null)
      min_5h=$(date -r "$last_ts_5h" "+%M" 2>/dev/null)
      ampm_5h=$(date -r "$last_ts_5h" "+%p" 2>/dev/null | tr '[:upper:]' '[:lower:]')
      if [ "$min_5h" = "00" ]; then
        time_5h="${hour_5h}${ampm_5h}"
      else
        time_5h="${hour_5h}:${min_5h}${ampm_5h}"
      fi
    fi
    if [ "$last_ts_7d" != "0" ] && [ "$last_ts_7d" != "null" ] && [ -n "$last_ts_7d" ]; then
      # 日付+時刻を "3/13 10am" / "3/13 2:30pm" 形式に変換
      md_7d=$(date -r "$last_ts_7d" "+%-m/%-d" 2>/dev/null)
      hour_7d=$(date -r "$last_ts_7d" "+%-H" 2>/dev/null)
      min_7d=$(date -r "$last_ts_7d" "+%M" 2>/dev/null)
      ampm_7d=$(date -r "$last_ts_7d" "+%p" 2>/dev/null | tr '[:upper:]' '[:lower:]')
      if [ "$min_7d" = "00" ]; then
        time_7d="${md_7d} ${hour_7d}${ampm_7d}"
      else
        time_7d="${md_7d} ${hour_7d}:${min_7d}${ampm_7d}"
      fi
    fi

    # パーセンテージ表示
    disp_5h_pct="${pct_5h}%"
    disp_7d_pct="${pct_7d}%"
    # 最終更新時刻を表示
    disp_5h_time="${time_5h:-N/A}"
    disp_7d_time="${time_7d:-N/A}"
    cost_line="💰 5h ${disp_5h_pct} (🔄 ${disp_5h_time}) | 7d ${disp_7d_pct} (🔄 ${disp_7d_time})"
  fi
else
  # 初回：キャッシュファイルを作成
  echo "[{\"session_id\": \"$session_id\", \"cost\": $session_cost, \"ts\": $now}]" > "$cache_file"
  cost_line="💰 5h 0.0% (🔄 --:--) | 7d 0.0% (🔄 --)"
fi

# ステータスラインを組み立て（最大 5 行）
printf "📁 %s\n" "$display_cwd"

if [ -n "$repo_name" ] || [ -n "$branch" ]; then
  repo_part=""
  if [ -n "$repo_name" ]; then
    repo_part="🐙 ${repo_name}"
  fi
  if [ -n "$branch" ]; then
    if [ -n "$repo_part" ]; then
      repo_part="${repo_part} │ 🌿 ${branch}"
    else
      repo_part="🌿 ${branch}"
    fi
  fi
  if [ -n "$git_diff_stat" ]; then
    repo_part="${repo_part} ${git_diff_stat}"
  fi
  printf "%s\n" "$repo_part"
fi

if [ -n "$context_line" ]; then
  printf "%s\n" "$context_line"
fi

if [ -n "$cost_line" ]; then
  if [ -n "$pr_number" ] && [ "$pr_number" != "null" ]; then
    printf "%s | PR #%s\n" "$cost_line" "$pr_number"
  else
    printf "%s\n" "$cost_line"
  fi
fi
