#!/bin/bash

# YouAreTheCEO - マルチエージェント並行開発システム
# Copyright (c) 2025 YouAreTheCEO Project

set -e

# 設定ファイルの読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config/system-config.sh"

# 関数定義
print_banner() {
    echo -e "${CEO_COLOR_SYSTEM}"
    echo "=========================================="
    echo "      YouAreTheCEO System v1.0"
    echo "   Parallel Development with Claude Code"
    echo "=========================================="
    echo -e "${CEO_COLOR_RESET}"
}

print_status() {
    echo -e "${CEO_COLOR_SYSTEM}[CEO System]${CEO_COLOR_RESET} $1"
}

print_error() {
    echo -e "${CEO_COLOR_ERROR}[ERROR]${CEO_COLOR_RESET} $1"
}

check_dependencies() {
    print_status "依存関係をチェック中..."
    
    if ! command -v tmux &> /dev/null; then
        print_error "tmux がインストールされていません"
        exit 1
    fi
    
    if ! command -v claude &> /dev/null; then
        print_error "Claude Code がインストールされていません"
        exit 1
    fi
    
    print_status "依存関係チェック完了"
}

cleanup_existing_session() {
    if tmux has-session -t "$CEO_SESSION" 2>/dev/null; then
        print_status "既存のセッション $CEO_SESSION をクリーンアップ中..."
        tmux kill-session -t "$CEO_SESSION"
        sleep 1
    fi
}

create_tmux_session() {
    print_status "tmux セッション '$CEO_SESSION' を作成中..."
    
    # セッション作成
    tmux new-session -d -s "$CEO_SESSION" -x 120 -y 40
    
    # ウィンドウ名を設定
    tmux rename-window -t "$CEO_SESSION:0" "CEO-Boss"
    
    # メインpaneでシステム初期化
    tmux send-keys -t "$CEO_SESSION:0" "cd '$SCRIPT_DIR'" C-m
    tmux send-keys -t "$CEO_SESSION:0" "echo 'CEO System initializing...'" C-m
    
    print_status "tmux セッション作成完了"
}

start_boss() {
    print_status "上司（Boss）を起動中..."
    
    # 上司を起動
    tmux send-keys -t "$CEO_SESSION:0" "echo 'Starting Boss (Opus)...'" C-m
    tmux send-keys -t "$CEO_SESSION:0" "$CC_BOSS" C-m
    
    # 初期化指示をマークダウンファイルから送信
    sleep 3
    tmux send-keys -t "$CEO_SESSION:0" "/read $SCRIPT_DIR/config/boss-instructions.md" C-m
    
    print_status "上司（Boss）起動完了"
}

initialize_system() {
    print_status "システムを初期化中..."
    
    # ログディレクトリの準備
    mkdir -p "$CEO_LOGS"
    mkdir -p "$CEO_COMM_DIR"
    
    # ステータスファイルの初期化
    echo "ready" > "$CEO_COMM_DIR/boss_status"
    echo "0" > "$CEO_COMM_DIR/worker_count"
    echo "" > "$CEO_COMM_DIR/task_queue"
    
    # 実行可能権限の設定
    chmod +x "$SCRIPT_DIR/scripts"/*.sh 2>/dev/null || true
    
    print_status "システム初期化完了"
}

show_usage() {
    echo -e "${CEO_COLOR_SYSTEM}"
    echo "=========================================="
    echo "      使用方法"
    echo "=========================================="
    echo "1. tmux セッションにアタッチ:"
    echo "   tmux attach-session -t $CEO_SESSION"
    echo ""
    echo "2. 上司に指示を出す:"
    echo "   直接メッセージを入力してください"
    echo ""
    echo "3. システム終了:"
    echo "   tmux kill-session -t $CEO_SESSION"
    echo ""
    echo "4. 現在のセッション状況確認:"
    echo "   tmux list-sessions"
    echo "=========================================="
    echo -e "${CEO_COLOR_RESET}"
}

# メイン実行
main() {
    print_banner
    
    check_dependencies
    cleanup_existing_session
    create_tmux_session
    initialize_system
    start_boss
    
    print_status "$CEO_MSG_READY"
    show_usage
    
    echo -e "${CEO_COLOR_BOSS}[Boss Ready]${CEO_COLOR_RESET} セッションにアタッチして指示を出してください："
    echo "tmux attach-session -t $CEO_SESSION"
}

# 実行
main "$@"