#!/bin/bash

# YouAreTheCEO System Configuration

# tmux セッション名
export CEO_SESSION="your-company"

# Claude Code エイリアス
export CC_BOSS="claude --model opus --dangerously-skip-permissions"
export CC_WORKER="claude --model sonnet --dangerously-skip-permissions"

# プロジェクトルートディレクトリ
export CEO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ログディレクトリ
export CEO_LOGS="$CEO_ROOT/logs"

# 通信用一時ファイル
export CEO_COMM_DIR="$CEO_LOGS/comm"

# デフォルト設定
export CEO_MAX_WORKERS=8
export CEO_DEFAULT_WORKERS=2

# 色設定
export CEO_COLOR_BOSS="\033[1;32m"
export CEO_COLOR_WORKER="\033[1;34m"
export CEO_COLOR_SYSTEM="\033[1;33m"
export CEO_COLOR_ERROR="\033[1;31m"
export CEO_COLOR_RESET="\033[0m"

# システムメッセージ
export CEO_MSG_STARTUP="YouAreTheCEO System starting..."
export CEO_MSG_READY="CEO System ready. Boss is waiting for your instructions."
export CEO_MSG_SHUTDOWN="CEO System shutting down..."

# 通信用ファイル作成
mkdir -p "$CEO_COMM_DIR"
touch "$CEO_COMM_DIR/boss_status"
touch "$CEO_COMM_DIR/worker_status"
touch "$CEO_COMM_DIR/task_queue"